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

// 1vs1 Battle endpoint using WebSocket (Socket.io)
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  // Join battle request
  socket.on('joinBattle', (data) => {
    const { username, battleId } = data;

    if (!activeBattles[battleId]) {
      // If the battle doesn't exist, create it and add the first player
      activeBattles[battleId] = { players: [username], status: 'waiting' };
      socket.join(battleId);
      io.to(battleId).emit('waitingForOpponent', { message: 'Waiting for another player...' });
    } else if (activeBattles[battleId].players.length === 1) {
      // If one player is already in, add the second player
      activeBattles[battleId].players.push(username);
      activeBattles[battleId].status = 'active';
      socket.join(battleId);
      io.to(battleId).emit('battleStart', { message: 'Battle started!', players: activeBattles[battleId].players });
    } else {
      // Battle is full
      socket.emit('battleFull', { message: 'This battle is already full.' });
    }
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log('A user disconnected:', socket.id);
    // Clean up any battle states here if necessary
  });
});

// Start the server
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
