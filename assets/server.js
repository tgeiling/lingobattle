require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const http = require('http');
const { Server } = require('socket.io');
const { v4: uuidv4 } = require('uuid');

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
  username: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  
  winStreak: { type: Number, default: 0 }, 
  exp: { type: Number, default: 0 }, 

  //JSON
  completedLevels: { type: String, default: "" },

  title: { type: String, default: "" },
  elo: { type: Number, default: 0 },
  skillLevel: { type: Number, default: 0 },
  
  createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model('User', UserSchema);

const MatchResultSchema = new mongoose.Schema({
  matchId: { type: String, required: true, unique: true },
  players: [
    {
      username: { type: String, required: true },
      correctAnswers: { type: Number, required: true },
      progress: { type: [String], default: [] }, // Tracks "correct", "wrong", "unanswered"
    },
  ],
  language: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

const MatchResult = mongoose.model('MatchResult', MatchResultSchema);
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

app.post('/updateProfile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.user.username });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update general user fields if present
    if (req.body.winStreak !== undefined) user.winStreak = req.body.winStreak;
    if (req.body.exp !== undefined) user.exp = req.body.exp;
    if (req.body.title !== undefined) user.title = req.body.title;
    if (req.body.elo !== undefined) user.elo = req.body.elo;
    if (req.body.skillLevel !== undefined) user.skillLevel = req.body.skillLevel;
    if (req.body.completedLevels !== undefined) user.completedLevels = req.body.completedLevels;

    await user.save();
    res.status(200).json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error("Profile update error:", error);
    res.status(500).json({ message: 'Server error' });
  }
});


app.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findOne({ username: req.user.username });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Return the user's profile data
    res.status(200).json({
      username: user.username,
      winStreak: user.winStreak,
      exp: user.exp,
      completedLevels: user.completedLevels,
      title: user.title,
      elo: user.elo,
      skillLevel: user.skillLevel,
    });
  } catch (error) {
    console.error("Fetching profile error:", error);
    res.status(500).json({ message: 'Server error' });
  }
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

app.get('/matchHistory/:username', authenticateToken, async (req, res) => {
  const { username } = req.params;

  try {
    const matches = await MatchResult.find({
      'players.username': username,
    }).sort({ createdAt: -1 });

    res.status(200).json(matches);
  } catch (error) {
    console.error('Error fetching match history:', error);
    res.status(500).json({ message: 'Failed to fetch match history' });
  }
});


// Socket.IO server setup
const server = http.createServer(app);

const io = new Server(server, { cors: { origin: '*' } });

// Active battles storage (in-memory)
let activeBattles = {};
let matchmakingQueue = []; // Players waiting for a match

// Timeout period for matchmaking (in milliseconds)
const MATCH_TIMEOUT = 60000; // 1 minute

const matchPlayers = async () => {
  while (matchmakingQueue.length >= 2) {
    const player1 = matchmakingQueue.shift();
    const player2 = matchmakingQueue.shift();

    clearTimeout(player1.timeout);
    clearTimeout(player2.timeout);

    // Fetch ELO for both players from MongoDB
    const user1 = await User.findOne({ username: player1.username });
    const user2 = await User.findOne({ username: player2.username });

    const elo1 = user1 ? user1.elo : 0;
    const elo2 = user2 ? user2.elo : 0;

    console.log("qweqweqweqwe");
    console.log("ELO1: " + elo1);
    console.log("ELO1: " + elo2);
    console.log("qweqweqweqwe");

    const battleId = `${player1.socket.id}-${player2.socket.id}`;
    activeBattles[battleId] = {
      players: [
        { id: player1.socket.id, username: player1.username, elo: elo1 },
        { id: player2.socket.id, username: player2.username, elo: elo2 },
      ],
      status: 'active',
    };

    console.log(`[MATCH CREATED] Battle ID: ${battleId}`);
    console.log(`    Player 1: ${player1.username} (ELO: ${elo1})`);
    console.log(`    Player 2: ${player2.username} (ELO: ${elo2})`);

    try {
      const matchResult = await MatchResult.findOneAndUpdate(
        { matchId: battleId },
        {
          $set: {
            players: [
              { username: player1.username, progress: Array(5).fill('unanswered'), correctAnswers: 0 },
              { username: player2.username, progress: Array(5).fill('unanswered'), correctAnswers: 0 },
            ],
            language: player1.language,
          },
        },
        { upsert: true, new: true }
      );

      console.log(`[MATCH CREATED] Saved match result to database for matchId: ${battleId}`);
    } catch (err) {
      console.error(`[DATABASE ERROR] Failed to save match results: ${err}`);
    }

    // Emit battleStart event to both players **with ELO included**
    io.to(player1.socket.id).emit('battleStart', {
      username: player1.username,
      matchId: battleId,
      opponentUsername: player2.username,
      language: player1.language,
      elo: elo1, // Added ELO
      opponentElo: elo2, // Added ELO
    });

    io.to(player2.socket.id).emit('battleStart', {
      username: player2.username,
      matchId: battleId,
      opponentUsername: player1.username,
      language: player2.language,
      elo: elo2, // Added ELO
      opponentElo: elo1, // Added ELO
    });

    console.log(`[BATTLE STARTED] Battle ID: ${battleId} with ELO ratings`);
  }
};



// Handle WebSocket connections
io.on('connection', (socket) => {
  console.log(`[CONNECTED] User connected: ${socket.id}`);

  // Join matchmaking queue
  socket.on('joinQueue', (data) => {
    const { username, language } = data;
    console.log(`[JOIN QUEUE] Username: ${username}, Language: ${language}, Socket ID: ${socket.id}`);
  
    // Create a player object with a reference to the timeout
    const player = {
      socket,
      username,
      language,
      timeout: setTimeout(() => {
        const isStillInQueue = matchmakingQueue.some((p) => p.socket.id === socket.id);
        if (isStillInQueue) {
          matchmakingQueue = matchmakingQueue.filter((p) => p.socket.id !== socket.id);
          socket.emit('timeout', { message: 'Matchmaking timeout. Please try again.' });
          console.log(`[TIMEOUT] Player ${username} (${socket.id}) removed from the queue due to timeout.`);
        }
      }, MATCH_TIMEOUT),
    };
  
    // Add the player to the matchmaking queue
    matchmakingQueue.push(player);
    console.log(`[QUEUE STATUS] Current queue length: ${matchmakingQueue.length}`);
  
    // Attempt to match players
    matchPlayers();
  });

  // Handle player disconnection
  socket.on('disconnect', async () => {
    console.log(`[DISCONNECTED] User disconnected: ${socket.id}`);

    // Remove from queue
    matchmakingQueue = matchmakingQueue.filter((player) => player.socket.id !== socket.id);

    // Find active battle
    for (const battleId in activeBattles) {
        const battle = activeBattles[battleId];
        const playerIndex = battle.players.findIndex((p) => p.id === socket.id);

        if (playerIndex !== -1) {
            const disconnectedPlayer = battle.players[playerIndex];
            const remainingPlayer = battle.players.find((p) => p.id !== socket.id);

            console.log(`[DISCONNECT] Player ${disconnectedPlayer.username} left Battle ID: ${battleId}`);

            // Fetch user data
            const user = await User.findOne({ username: disconnectedPlayer.username });
            const remainingUser = await User.findOne({ username: remainingPlayer.username });

            // Adjust ELO and EXP
            let newElo = Math.max(0, user.elo - 15);
            let newExp = Math.max(0, user.exp - 100);

            // Reset win streak
            await User.updateOne({ username: disconnectedPlayer.username }, { elo: newElo, exp: newExp, winStreak: 0 });

            console.log(`[ELO UPDATE] ${disconnectedPlayer.username} penalized for disconnection. New ELO: ${newElo}`);

            // Notify remaining player
            io.to(remainingPlayer.id).emit('battleEnded', {
                message: 'Your opponent disconnected. You win!',
                result: 'opponentDisconnected',
            });

            // Reward remaining player
            let newEloWin = remainingUser.elo + 15;
            let newExpWin = remainingUser.exp + 100;
            let newWinStreak = remainingUser.winStreak + 1;

            await User.updateOne({ username: remainingPlayer.username }, { elo: newEloWin, exp: newExpWin, winStreak: newWinStreak });

            console.log(`[ELO UPDATE] ${remainingPlayer.username} awarded. New ELO: ${newEloWin}`);

            // Remove battle from active list
            delete activeBattles[battleId];
        }
    }
  });


  socket.on('submitAnswer', async (data) => {
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
  
        // Save progress to MongoDB
        try {
          const match = await MatchResult.findOne({ matchId });
  
          if (match) {
            // Update the current player's progress in the database
            const playerInDB = match.players.find((p) => p.username === username);
  
            if (playerInDB) {
              playerInDB.progress[questionIndex] = status;
              await match.save();
              console.log(`[DATABASE UPDATE] Updated progress for ${username} in match ${matchId}`);
            } else {
              console.log(`[DATABASE ERROR] Player ${username} not found in database match record`);
            }
          } else {
            console.log(`[DATABASE ERROR] Match ID ${matchId} not found in database`);
          }
        } catch (err) {
          console.error(`[DATABASE ERROR] Failed to update match progress: ${err}`);
        }
      } else {
        console.log(`[ERROR] Player or opponent not found in battle ${matchId}`);
      }
    } else {
      console.log(`[ERROR] Match ID ${matchId} not found in active battles`);
    }
  }); 

  socket.on('submitResults', async (data) => {
    const { matchId, username, correctAnswers, language } = data;

    console.log(`[SUBMIT RESULTS] Received results from ${username} for match ${matchId}`);

    if (activeBattles[matchId]) {
        const battle = activeBattles[matchId];
        const player = battle.players.find((p) => p.username === username);

        if (player) {
            player.correctAnswers = correctAnswers;

            // Check if both players have submitted their results
            if (battle.players.every((p) => p.correctAnswers !== undefined)) {
                const [player1, player2] = battle.players;

                try {
                    // Save match results to MongoDB
                    const matchResult = await MatchResult.findOneAndUpdate(
                        { matchId },
                        {
                            $set: {
                                players: [
                                    {
                                        username: player1.username,
                                        correctAnswers: player1.correctAnswers,
                                        progress: player1.progress,
                                    },
                                    {
                                        username: player2.username,
                                        correctAnswers: player2.correctAnswers,
                                        progress: player2.progress,
                                    },
                                ],
                                language: language,
                            },
                        },
                        { upsert: true, new: true }
                    );

                    console.log(`[MATCH SAVED] Results saved for match ${matchId}`);
                } catch (err) {
                    console.error(`[DATABASE ERROR] Failed to save match results: ${err}`);
                }

                // Determine the winner
                let winner = null;
                if (player1.correctAnswers > player2.correctAnswers) {
                    winner = player1.username;
                } else if (player2.correctAnswers > player1.correctAnswers) {
                    winner = player2.username;
                }

                console.log(`Winner: ${winner || 'Draw'}`);

                // Fetch users from DB
                const user1 = await User.findOne({ username: player1.username });
                const user2 = await User.findOne({ username: player2.username });

                let winStreak1 = user1?.winStreak || 0;
                let exp1 = user1?.exp || 0;
                let elo1 = user1?.elo || 0;

                let winStreak2 = user2?.winStreak || 0;
                let exp2 = user2?.exp || 0;
                let elo2 = user2?.elo || 0;

                if (winner === player1.username) {
                    winStreak1 += 1;
                    exp1 += 100;
                    elo1 += 15;
                    winStreak2 = 0;
                    exp2 = Math.max(0, exp2 - 100);
                    elo2 = Math.max(0, elo2 - 15);
                } else if (winner === player2.username) {
                    winStreak2 += 1;
                    exp2 += 100;
                    elo2 += 15;
                    winStreak1 = 0;
                    exp1 = Math.max(0, exp1 - 100);
                    elo1 = Math.max(0, elo1 - 15);
                } else { // Draw case
                    winStreak1 = 0;
                    winStreak2 = 0;
                    exp1 = Math.max(0, exp1 - 5);
                    elo1 = Math.max(0, elo1 - 5);
                    exp2 = Math.max(0, exp2 - 5);
                    elo2 = Math.max(0, elo2 - 5);
                }

                // Update user profiles in the database
                await User.updateOne({ username: player1.username }, { winStreak: winStreak1, exp: exp1, elo: elo1 });
                await User.updateOne({ username: player2.username }, { winStreak: winStreak2, exp: exp2, elo: elo2 });

                console.log(`[PROFILE UPDATE] ${player1.username} - ELO: ${elo1}, EXP: ${exp1}, WinStreak: ${winStreak1}`);
                console.log(`[PROFILE UPDATE] ${player2.username} - ELO: ${elo2}, EXP: ${exp2}, WinStreak: ${winStreak2}`);

                // Notify both players of the match outcome
                battle.players.forEach((p) => {
                    io.to(p.id).emit('battleEnded', {
                        message: 'Match finished!',
                        result: {
                            winner,
                            player1: {
                                username: player1.username,
                                progress: player1.progress,
                                correctAnswers: player1.correctAnswers,
                                elo: elo1,
                                exp: exp1,
                                winStreak: winStreak1
                            },
                            player2: {
                                username: player2.username,
                                progress: player2.progress,
                                correctAnswers: player2.correctAnswers,
                                elo: elo2,
                                exp: exp2,
                                winStreak: winStreak2
                            },
                        },
                    });
                });

                // Remove the match from active battles
                delete activeBattles[matchId];
            }
        }
    } else {
        console.log(`[ERROR] Match ID ${matchId} not found in active battles`);
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
