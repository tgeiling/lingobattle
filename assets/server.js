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
const rateLimit = require("express-rate-limit");

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
      progress: { type: [String], default: [] }, // "correct", "wrong", "unanswered"
    },
  ],
  language: { type: String, required: true },
  questions: [
    {
      question: { type: String, required: true },
      answers: { type: [String], required: true },
    },
  ],
  createdAt: { type: Date, default: Date.now },
});

const MatchResult = mongoose.model('MatchResult', MatchResultSchema);


const QuestionSchema = new mongoose.Schema({
  language: { type: String, required: true },
  question: { type: String, required: true },
  answers: { type: [String], required: true }
});

const Question = mongoose.model('Question', QuestionSchema);
module.exports = { User, MatchResult, Question };

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'lingobattle_secret';

app.get('/test', (req, res) => {
    res.status(200).json({ message: 'Test endpoint is working!' });
  });

const badWords = ["admin", "moderator", "fuck", "shit", "bitch", "asshole"]; // Add more as needed

// Helper function to validate username
function validateUsername(username) {
    const regex = /^[a-zA-Z0-9_]+$/;
    let errors = [];

    if (!regex.test(username)) errors.push("Username can only contain letters, numbers, and underscores.");
    if (username.length < 3 || username.length > 16) errors.push("Username must be between 3 and 16 characters.");
    if (badWords.some(word => username.toLowerCase().includes(word))) errors.push("Username contains forbidden words.");

    return errors;
}

app.post('/register', async (req, res) => {
    try {
        const { username, password } = req.body;

        // Validate username
        const errors = validateUsername(username);
        if (errors.length > 0) {
            return res.status(400).json({ message: "Invalid username", errors });
        }

        // Check if username already exists
        const existingUser = await User.findOne({ username });
        if (existingUser) {
            return res.status(400).json({ message: "Username already exists", errors: ["This username is already taken."] });
        }

        // Hash the password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create new user
        const user = new User({ username, password: hashedPassword });
        await user.save();

        res.status(201).json({ message: "User registered successfully" });
    } catch (error) {
        console.error("Registration error:", error);
        res.status(500).json({ message: "Server error" });
    }
});

const loginLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // Max 5 login attempts per minute
  message: { message: "Too many login attempts. Please try again later." },
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/login', loginLimiter, async (req, res) => {
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

  const token = jwt.sign({ id: user._id, username: user.username }, JWT_SECRET, { expiresIn: '12h' });
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

app.get('/leaderboard', async (req, res) => {
  try {
      let { page = 1, limit = 20, username } = req.query;
      page = parseInt(page);
      limit = parseInt(limit);

      // Fetch paginated leaderboard
      const topPlayers = await User.find({})
          .sort({ elo: -1 }) // Sort by ELO
          .skip((page - 1) * limit) // Pagination logic
          .limit(limit)
          .select('username elo winStreak');

      let userRank = null;
      if (username) {
          const user = await User.findOne({ username }).select('elo');
          if (user) {
              userRank = await User.countDocuments({ elo: { $gt: user.elo } }) + 1;
          }
      }

      res.status(200).json({ leaderboard: topPlayers, userRank });
  } catch (error) {
      console.error('Error fetching leaderboard:', error);
      res.status(500).json({ message: 'Failed to fetch leaderboard' });
  }
});



// Socket.IO server setup
const server = http.createServer(app);

const io = new Server(server, { cors: { origin: '*' } });

// Active battles storage (in-memory)
let activeBattles = {};
let matchmakingQueue = []; // Players waiting for a match

// Timeout period for matchmaking (in milliseconds)
const MATCH_TIMEOUT = 301000; // 1 minute

const matchPlayers = async () => {
  while (matchmakingQueue.length >= 2) {
    const player1 = matchmakingQueue.shift();
    const player2 = matchmakingQueue.shift();

    if (player1.username === player2.username) {
      console.log(`[ERROR] Player ${player1.username} tried to match with themselves.`);
      matchmakingQueue.push(player2);
      continue;
    }

    clearTimeout(player1.timeout);
    clearTimeout(player2.timeout);

    // Fetch ELO ratings from MongoDB
    const user1 = await User.findOne({ username: player1.username });
    const user2 = await User.findOne({ username: player2.username });

    const elo1 = user1 ? user1.elo : 0;
    const elo2 = user2 ? user2.elo : 0;

    const battleId = `${player1.socket.id}-${player2.socket.id}`;

    // **Fetch 5 random questions for the selected language**
    let questions = await Question.aggregate([
      { $match: { language: player1.language } }, // Filter by language
      { $sample: { size: 5 } } // Pick 5 random questions
    ]);

    if (!questions.length) {
      console.log(`[ERROR] No questions found for language ${player1.language}`);
      continue;
    }

    // **Save match details including questions**
    activeBattles[battleId] = {
      players: [
        { id: player1.socket.id, username: player1.username, elo: elo1 },
        { id: player2.socket.id, username: player2.username, elo: elo2 },
      ],
      status: 'active',
      questions: questions.map(q => ({
        question: q.question,
        answers: q.answers,
      })),
    };

    console.log(`[MATCH CREATED] Battle ID: ${battleId}`);

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
            questions: questions.map(q => ({
              question: q.question,
              answers: q.answers,
            })),
          },
        },
        { upsert: true, new: true }
      );

      console.log(`[MATCH CREATED] Saved match result to database.`);
    } catch (err) {
      console.error(`[DATABASE ERROR] Failed to save match results: ${err}`);
    }

    // Emit battleStart event with questions
    io.to(player1.socket.id).emit('battleStart', {
      username: player1.username,
      matchId: battleId,
      opponentUsername: player2.username,
      language: player1.language,
      elo: elo1,
      opponentElo: elo2,
      questions, // Send questions
    });

    io.to(player2.socket.id).emit('battleStart', {
      username: player2.username,
      matchId: battleId,
      opponentUsername: player1.username,
      language: player2.language,
      elo: elo2,
      opponentElo: elo1,
      questions, // Send questions
    });

    console.log(`[BATTLE STARTED] Sent questions to both players.`);
  }
};




// Handle WebSocket connections
io.on('connection', (socket) => {
  console.log(`[CONNECTED] User connected: ${socket.id}`);

  const matchmakingAttempts = new Map();

  socket.on('joinQueue', (data) => {
    const { username, language } = data;
    const now = Date.now();

    // Rate limit: Allow max 3 matchmaking requests per minute per user
    if (!matchmakingAttempts.has(username)) {
        matchmakingAttempts.set(username, []);
    }

    const timestamps = matchmakingAttempts.get(username);
    const filteredTimestamps = timestamps.filter(timestamp => now - timestamp < 60 * 1000); // Keep only the last 60 seconds
    filteredTimestamps.push(now);

    if (filteredTimestamps.length > 3) {
        console.log(`[RATE LIMIT] Matchmaking spam detected for ${username}`);
        socket.emit('joinQueueError', { message: 'Too many matchmaking attempts. Try again in a minute.' });
        return;
    }

    matchmakingAttempts.set(username, filteredTimestamps);

    // Validate username (empty check)
    if (!username || username.trim().length === 0) {
        console.log(`[ERROR] Empty username attempted matchmaking.`);
        socket.emit('joinQueueError', { message: 'Invalid username. Please set a username in your profile.' });
        return;
    }

    // Check if username exists in DB
    User.findOne({ username }).then(user => {
        if (!user) {
            console.log(`[ERROR] User ${username} not found.`);
            socket.emit('joinQueueError', { message: 'User not found. Please log in again.' });
            return;
        }

        console.log(`[JOIN QUEUE] Username: ${username}, Language: ${language}, Socket ID: ${socket.id}`);

        // Remove any existing queue entry for this player before adding them
        matchmakingQueue = matchmakingQueue.filter((p) => p.username !== username);

        // Create a player object with a reference to the timeout
        const player = {
            socket,
            username,
            language,
            timeout: setTimeout(() => {
                const isStillInQueue = matchmakingQueue.some((p) => p.socket.id === socket.id);
                if (isStillInQueue) {
                    matchmakingQueue = matchmakingQueue.filter((p) => p.socket.id !== socket.id);
                    socket.emit('joinQueueError', { message: 'Matchmaking timeout. Please try again.' });
                    console.log(`[TIMEOUT] Player ${username} (${socket.id}) removed from the queue due to timeout.`);
                }
            }, MATCH_TIMEOUT),
        };

        // Add the player to the matchmaking queue
        matchmakingQueue.push(player);
        console.log(`[QUEUE STATUS] Current queue length: ${matchmakingQueue.length}`);

        // Attempt to match players
        matchPlayers();
    }).catch(error => {
        console.error(`[DATABASE ERROR] Failed to fetch user: ${error}`);
        socket.emit('joinQueueError', { message: 'Server error. Please try again later.' });
    });
  });



  socket.on('playerLeft', async (data) => {
    const { matchId, username } = data;

    console.log(`[PLAYER LEFT] ${username} left the match ${matchId}`);

    if (activeBattles[matchId]) {
        const battle = activeBattles[matchId];
        const leavingPlayer = battle.players.find((p) => p.username === username);
        const remainingPlayer = battle.players.find((p) => p.username !== username);

        if (leavingPlayer && remainingPlayer) {
            console.log(`[FORFEIT] ${username} forfeited. ${remainingPlayer.username} wins.`);

            // Fetch user data
            const user = await User.findOne({ username: leavingPlayer.username });
            const remainingUser = await User.findOne({ username: remainingPlayer.username });

            if (user && remainingUser) {
                // Penalize the leaving player
                let newElo = Math.max(0, user.elo - 15);
                let newExp = Math.max(0, user.exp - 100);
                await User.updateOne({ username: leavingPlayer.username }, { 
                    elo: newElo, 
                    exp: newExp, 
                    winStreak: 0  // Reset win streak for leaver
                });

                // Reward the remaining player
                let newEloWin = remainingUser.elo + 15;
                let newExpWin = remainingUser.exp + 100;
                let newWinStreak = remainingUser.winStreak + 1;
                await User.updateOne({ username: remainingPlayer.username }, { 
                    elo: newEloWin, 
                    exp: newExpWin, 
                    winStreak: newWinStreak  // Increase win streak
                });

                console.log(`[ELO UPDATE] ${leavingPlayer.username} penalized. New ELO: ${newElo}`);
                console.log(`[ELO UPDATE] ${remainingPlayer.username} awarded. New ELO: ${newEloWin}, New Win Streak: ${newWinStreak}`);

                io.to(remainingPlayer.id).emit('battleEnded', {
                    message: 'Opponent left. You win!',
                    result: 'playerLeft',
                    questions: battle.questions || [],
                });

                delete activeBattles[matchId];
            }
        }
    }
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

            if (!remainingPlayer) {
                console.log(`[INFO] No remaining player. Removing battle.`);
                delete activeBattles[battleId];
                return;
            }

            const remainingUser = await User.findOne({ username: remainingPlayer.username });

            if (user && remainingUser) {
                // Penalize disconnected player
                let newElo = Math.max(0, user.elo - 15);
                let newExp = Math.max(0, user.exp - 100);
                await User.updateOne({ username: disconnectedPlayer.username }, { 
                    elo: newElo, 
                    exp: newExp, 
                    winStreak: 0  // Reset win streak for disconnector
                });

                // Reward the remaining player
                let newEloWin = remainingUser.elo + 15;
                let newExpWin = remainingUser.exp + 100;
                let newWinStreak = remainingUser.winStreak + 1;
                await User.updateOne({ username: remainingPlayer.username }, { 
                    elo: newEloWin, 
                    exp: newExpWin, 
                    winStreak: newWinStreak  // Increase win streak
                });

                console.log(`[ELO UPDATE] ${disconnectedPlayer.username} penalized. New ELO: ${newElo}`);
                console.log(`[ELO UPDATE] ${remainingPlayer.username} awarded. New ELO: ${newEloWin}, New Win Streak: ${newWinStreak}`);

                // Notify remaining player
                io.to(remainingPlayer.id).emit('battleEnded', {
                    message: 'Your opponent disconnected. You win!',
                    result: 'opponentDisconnected',
                    questions: battle.questions || [],
                });

                // Remove battle from active list
                delete activeBattles[battleId];
            }
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
                    // Save match results to MongoDB, including questions
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
                                questions: battle.questions.map(q => ({
                                    question: q.question,
                                    answers: q.answers
                                })), // Save questions from the battle
                            },
                        },
                        { upsert: true, new: true }
                    );

                    console.log(`[MATCH SAVED] Results and questions saved for match ${matchId}`);
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
                        questions: battle.questions || [],
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
