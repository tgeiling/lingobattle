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

app.post('/validateToken', async (req, res) => {
  const { token } = req.body;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findOne({ username: decoded.username });
    if (user) {
      res.json({ isValid: true });
    } else {
      res.json({ isValid: false, reason: "No user found" });
    }
  } catch (error) {
    res.status(400).send({ isValid: false, reason: "Invalid token" });
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



// Socket.IO server setup
const server = http.createServer(app);

const io = new Server(server, { cors: { origin: '*' } });

// Active battles storage (in-memory)
let activeBattles = {};
let matchmakingQueue = []; // Players waiting for a match

// Timeout period for matchmaking (in milliseconds)
const MATCH_TIMEOUT = 60000; // 1 minute

// Matchmaking handler
const matchPlayers = () => {
  while (matchmakingQueue.length >= 2) {
    const player1 = matchmakingQueue.shift();
    const player2 = matchmakingQueue.shift();

    const battleId = `${player1.socket.id}-${player2.socket.id}`;
    activeBattles[battleId] = {
      players: [
        { id: player1.socket.id, username: player1.username },
        { id: player2.socket.id, username: player2.username },
      ],
      status: 'active',
    };

    console.log(`[MATCH CREATED] Battle ID: ${battleId}`);
    console.log(`    Player 1: ${player1.username} (${player1.socket.id})`);
    console.log(`    Player 2: ${player2.username} (${player2.socket.id})`);

    // Emit battleStart event to both players
    io.to(player1.socket.id).emit('battleStart', {
      username: player1.username,
      matchId: battleId,
      opponentUsername: player2.username,
      language: player1.language,
    });

    io.to(player2.socket.id).emit('battleStart', {
      username: player2.username,
      matchId: battleId,
      opponentUsername: player1.username,
      language: player2.language,
    });

    console.log(`[BATTLE STARTED] Battle ID: ${battleId}`);
  }
};

// Handle WebSocket connections
io.on('connection', (socket) => {
  console.log(`[CONNECTED] User connected: ${socket.id}`);

  // Join matchmaking queue
  socket.on('joinQueue', (data) => {
    const { username, language } = data;
    console.log(`[JOIN QUEUE] Username: ${username}, Language: ${language}, Socket ID: ${socket.id}`);

    // Add player to the matchmaking queue
    matchmakingQueue.push({ socket, username, language });
    console.log(`[QUEUE STATUS] Current queue length: ${matchmakingQueue.length}`);

    // Attempt to match players
    matchPlayers();

    // Add a timeout to remove the player from the queue
    setTimeout(() => {
      const isStillInQueue = matchmakingQueue.some((player) => player.socket.id === socket.id);
      if (isStillInQueue) {
        matchmakingQueue = matchmakingQueue.filter((player) => player.socket.id !== socket.id);
        socket.emit('timeout', { message: 'Matchmaking timeout. Please try again.' });
        console.log(`[TIMEOUT] Player ${username} (${socket.id}) removed from the queue due to timeout.`);
      }
    }, MATCH_TIMEOUT);
  });

  // Handle player disconnection
  socket.on('disconnect', () => {
    console.log(`[DISCONNECTED] User disconnected: ${socket.id}`);

    // Remove player from the matchmaking queue
    matchmakingQueue = matchmakingQueue.filter((player) => player.socket.id !== socket.id);
    console.log(`[QUEUE STATUS] Player ${socket.id} removed from the queue. Current queue length: ${matchmakingQueue.length}`);

    // Check if the player was part of an active battle
    for (const battleId in activeBattles) {
      const battle = activeBattles[battleId];
      const playerIndex = battle.players.findIndex((player) => player.id === socket.id);

      if (playerIndex !== -1) {
        const disconnectedPlayer = battle.players[playerIndex];
        battle.players.splice(playerIndex, 1);
        console.log(`[BATTLE UPDATE] Player ${disconnectedPlayer.username} (${disconnectedPlayer.id}) disconnected from Battle ID: ${battleId}`);

        if (battle.players.length === 0) {
          // No players remain, remove the battle
          delete activeBattles[battleId];
          console.log(`[BATTLE REMOVED] Battle ${battleId} removed as no players remain.`);
        } else {
          // Notify the remaining player
          const remainingPlayer = battle.players[0];
          io.to(remainingPlayer.id).emit('battleEnded', {
            message: 'Your opponent has disconnected. The battle has ended.',
            result: 'opponentDisconnected',
          });
          console.log(`[NOTIFIED] Remaining player ${remainingPlayer.username} (${remainingPlayer.id}) about opponent disconnection.`);
        }
      }
    }
  });

  socket.on('submitAnswer', (data) => {
    const { matchId, username, questionIndex, status } = data;
  
    console.log(`[SUBMIT ANSWER] Received answer from ${username} for question ${questionIndex}`);
  
    // Check if the match exists in active battles
    if (activeBattles[matchId]) {
      const battle = activeBattles[matchId];
      const currentPlayer = battle.players.find((p) => p.username === username);
      const opponent = battle.players.find((p) => p.username !== username);
  
      if (currentPlayer && opponent) {
        // Update progress for the current player
        currentPlayer.progress = currentPlayer.progress || [];
        currentPlayer.progress[questionIndex] = status; // "correct" or "wrong"
        console.log(`[PLAYER PROGRESS] ${username}:`, currentPlayer.progress);
  
        // Notify the opponent about the progress
        io.to(opponent.id).emit('progressUpdate', {
          questionIndex,
          status, // "correct" or "wrong"
        });
        console.log(
          `[PROGRESS UPDATE] Sent progress of ${username} to opponent ${opponent.username}`
        );
      } else {
        console.log(`[ERROR] Player or opponent not found in battle ${matchId}`);
      }
    } else {
      console.log(`[ERROR] Match ID ${matchId} not found in active battles`);
    }
  });
  
  

  // Submit results
  socket.on('submitResults', (data) => {
    const { matchId, username, correctAnswers } = data;

    if (activeBattles[matchId]) {
      const battle = activeBattles[matchId];
      const player = battle.players.find((p) => p.username === username);
      if (player) {
        player.correctAnswers = correctAnswers;

        // Check if both players have submitted their results
        if (battle.players.every((p) => p.correctAnswers !== undefined)) {
          // Determine winner
          const [player1, player2] = battle.players;
          let winner = null;
          if (player1.correctAnswers > player2.correctAnswers) {
            winner = player1.username;
          } else if (player2.correctAnswers > player1.correctAnswers) {
            winner = player2.username;
          }

          // Notify both players
          battle.players.forEach((p) => {
            io.to(p.id).emit('battleResults', {
              winner,
              player1Score: player1.correctAnswers,
              player2Score: player2.correctAnswers,
            });
          });

          // Remove the battle
          delete activeBattles[matchId];
        }
      }
    }
  });

  // Leave matchmaking queue
  socket.on('leaveQueue', () => {
    matchmakingQueue = matchmakingQueue.filter((player) => player.socket.id !== socket.id);
    console.log(`[LEAVE QUEUE] Player ${socket.id} left the matchmaking queue. Current queue length: ${matchmakingQueue.length}`);
  });
});

// Start the server
server.listen(PORT, () => {
  console.log(`[SERVER STARTED] Server is running on port ${PORT}`);
});
