require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const http = require('http');
const { Server } = require('socket.io');

// Create express app
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(helmet());
app.use(cors());

// MongoDB connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log('MongoDB connection error:', err));

// User schema and model
const UserSchema = new mongoose.Schema({
  username: { type: String, unique: true },
  password: String,
  winStreak: { type: Number, default: 0 },
  exp: { type: Number, default: 0 },
  completedLevels: { type: Number, default: 0 }
});

const User = mongoose.model('User', UserSchema);

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'lingobattle_secret';

app.get('/test', (req, res) => {
    res.status(200).json({ message: 'Test endpoint is working!' });
  });

// Register endpoint
// Register endpoint
app.post('/register', async (req, res) => {
    try {
      const { username, password } = req.body;
  
      // Check if username already exists
      const existingUser = await User.findOne({ username });
      if (existingUser) {
        return res.status(400).json({ message: 'Username already exists' });
      }
  
      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Create new user
      const user = new User({ username, password: hashedPassword });
      await user.save();
  
      res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).send('Server error');
    }
  });

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(`Login attempt for username: ${username}`);
  
    const user = await User.findOne({ username });
    
    if (!user) {
      console.log('User not found');
      return res.status(400).json({ message: 'User not found' });
    }
  
    const isMatch = await bcrypt.compare(password, user.password);
    console.log(`Password match: ${isMatch}`);
  
    if (!isMatch) {
      console.log('Invalid credentials');
      return res.status(400).json({ message: 'Invalid credentials' });
    }
  
    const token = jwt.sign({ id: user._id, username: user.username }, JWT_SECRET, { expiresIn: '1d' });
    console.log('Authentication successful, sending token');
    res.json({ token });
  });

// Guest token generation endpoint
app.post('/guestnode', (req, res) => {
  try {
    const guestToken = jwt.sign({ guest: true }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ accessToken: guestToken });
  } catch (error) {
    console.error('Error generating guest token:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/validateToken', (req, res) => {
    console.log('Token validation endpoint hit');
    const token = req.body.token;
    if (!token) return res.status(400).json({ message: 'Token required' });
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      res.json({ isValid: true, decoded });
    } catch (err) {
      res.status(401).json({ isValid: false, message: 'Invalid or expired token' });
    }
  });

// Middleware to authenticate token
function authenticateToken(req, res, next) {
  const token = req.header('Authorization')?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access denied' });

  try {
    const verified = jwt.verify(token, JWT_SECRET);
    req.user = verified;
    next();
  } catch (err) {
    res.status(400).json({ message: 'Invalid token' });
  }
}

// Create an HTTP server and Socket.io server for real-time communication
const server = http.createServer(app);
const io = new Server(server);

// Active battles storage (in-memory)
let activeBattles = {};

// Timeout period for waiting (in milliseconds)
const WAIT_TIMEOUT = 60000; // 1 minute

// Function to clean up battle data
const cleanupBattle = (battleId) => {
  if (activeBattles[battleId]) {
    io.to(battleId).emit('battleCancelled', { message: 'Battle has been cancelled due to inactivity or player disconnection.' });
    delete activeBattles[battleId]; // Remove the battle
  }
};

// 1vs1 Battle endpoint using WebSocket (Socket.io)
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  // Join battle request
  socket.on('joinBattle', (data) => {
    const { username, battleId } = data;

    if (!activeBattles[battleId]) {
      // If the battle doesn't exist, create it and add the first player
      activeBattles[battleId] = { players: [{ id: socket.id, username }], status: 'waiting', timeout: null };

      socket.join(battleId);
      io.to(battleId).emit('waitingForOpponent', { message: 'Waiting for another player...' });

      // Set a timeout to clean up the battle if no opponent joins
      activeBattles[battleId].timeout = setTimeout(() => cleanupBattle(battleId), WAIT_TIMEOUT);
    } else if (activeBattles[battleId].players.length === 1) {
      // If one player is already in, add the second player
      activeBattles[battleId].players.push({ id: socket.id, username });
      activeBattles[battleId].status = 'active';
      
      // Clear the waiting timeout since both players are present
      clearTimeout(activeBattles[battleId].timeout);
      activeBattles[battleId].timeout = null;

      socket.join(battleId);
      io.to(battleId).emit('battleStart', { 
        message: 'Battle started!', 
        players: activeBattles[battleId].players.map(player => player.username) 
      });
    } else {
      // Battle is full
      socket.emit('battleFull', { message: 'This battle is already full.' });
    }
  });

  // Handle player leaving or disconnecting
  socket.on('disconnect', () => {
    console.log('A user disconnected:', socket.id);

    // Find and clean up the battle the player was in
    for (const battleId in activeBattles) {
      const battle = activeBattles[battleId];
      const playerIndex = battle.players.findIndex((player) => player.id === socket.id);

      if (playerIndex !== -1) {
        // Remove the player from the battle
        battle.players.splice(playerIndex, 1);
        
        if (battle.players.length === 0) {
          // If no players remain, clean up the battle
          cleanupBattle(battleId);
        } else {
          // If one player remains, change status to waiting
          battle.status = 'waiting';
          io.to(battleId).emit('waitingForOpponent', { message: 'Your opponent has disconnected. Waiting for a new player...' });

          // Start a timeout to auto-cancel if no one joins
          battle.timeout = setTimeout(() => cleanupBattle(battleId), WAIT_TIMEOUT);
        }
      }
    }
  });

  // Leave battle manually (in case you need a separate leave event)
  socket.on('leaveBattle', (battleId) => {
    if (activeBattles[battleId]) {
      const playerIndex = activeBattles[battleId].players.findIndex((player) => player.id === socket.id);

      if (playerIndex !== -1) {
        activeBattles[battleId].players.splice(playerIndex, 1);
        
        if (activeBattles[battleId].players.length === 0) {
          cleanupBattle(battleId);
        } else {
          activeBattles[battleId].status = 'waiting';
          io.to(battleId).emit('waitingForOpponent', { message: 'Your opponent has left the battle. Waiting for a new player...' });
          activeBattles[battleId].timeout = setTimeout(() => cleanupBattle(battleId), WAIT_TIMEOUT);
        }
      }

      socket.leave(battleId);
    }
  });
});

// Start the server
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
