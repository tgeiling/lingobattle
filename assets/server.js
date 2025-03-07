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

const defaultElo = {
  english: 0,
  german: 0,
  swiss: 0,
  dutch: 0,
  spanish: 0,
};

const UserSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  password: { type: String, required: true },

  winStreak: { type: Number, default: 0 }, 
  exp: { type: Number, default: 0 }, 
  coins: { type: Number, default: 0 },  

  completedLevels: { type: String, default: "" }, // JSON String
  title: { type: String, default: "" },
  skillLevel: { type: Number, default: 0 },

  // ELO stored as a Map with default values
  elo: { type: Map, of: Number, default: defaultElo },

  nativeLanguage: { type: String, default: "" },
  acceptedGdpr: { type: Boolean, default: false },

  friends: { type: [String], default: [] },

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
  answers: { type: [String], required: true },
  difficulty: { type: Number, required: true },
  type: { type: String, required: true}
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

      // Validate password length
      if (!password || password.length < 6) {
          return res.status(400).json({ 
              message: "Invalid password", 
              errors: ["Password must be at least 6 characters long."] 
          });
      }

      // Check if username already exists
      const existingUser = await User.findOne({ username });
      if (existingUser) {
          return res.status(400).json({ 
              message: "Username already exists", 
              errors: ["This username is already taken."] 
          });
      }

      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Default ELO for all supported languages
      const defaultElo = {
          english: 0,
          german: 0,
          swiss: 0,
          dutch: 0,
          spanish: 0
      };

      // Create new user with initialized ELO
      const user = new User({ username, password: hashedPassword, elo: defaultElo });
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
    if (req.body.coins !== undefined) user.coins = req.body.coins;
    if (req.body.title !== undefined) user.title = req.body.title;
    if (req.body.elo !== undefined) user.elo = req.body.elo;
    if (req.body.skillLevel !== undefined) user.skillLevel = req.body.skillLevel;
    if (req.body.completedLevels !== undefined) user.completedLevels = req.body.completedLevels;
    if (req.body.nativeLanguage !== undefined) user.nativeLanguage = req.body.nativeLanguage;
    if (req.body.acceptedGdpr !== undefined) user.acceptedGdpr = req.body.acceptedGdpr;
    if (req.body.friends !== undefined) user.friends = req.body.friends;

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
      coins: user.coins,
      completedLevels: user.completedLevels,
      title: user.title,
      elo: user.elo,
      skillLevel: user.skillLevel,
      nativeLanguage: user.nativeLanguage,
      acceptedGdpr: user.acceptedGdpr,
      friends: user.friends,
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

app.get("/friends/search", async (req, res) => {
  const { query } = req.query;

  if (!query || query.trim() === "") {
      return res.status(400).json({ message: "Search query is required." });
  }

  try {
      // Case-insensitive search using regex
      const users = await User.find({ username: { $regex: query, $options: "i" } })
          .limit(10) // Limit to 10 results
          .select("username");

      return res.status(200).json({ users });
  } catch (error) {
      console.error("Error searching for friends:", error);
      return res.status(500).json({ message: "Internal server error." });
  }
});

app.get("/friends/list", async (req, res) => {
  const { username } = req.query;

  if (!username) {
      return res.status(400).json({ message: "Username is required." });
  }

  try {
      const user = await User.findOne({ username }).select("friends");
      if (!user) {
          return res.status(404).json({ message: "User not found." });
      }

      return res.status(200).json({ friends: user.friends });
  } catch (error) {
      console.error("Error fetching friends:", error);
      return res.status(500).json({ message: "Internal server error." });
  }
});

// ✅ Add a friend
app.post("/friends/add", async (req, res) => {
  const { username, friendUsername } = req.body;

  if (!username || !friendUsername) {
      return res.status(400).json({ message: "Both usernames are required." });
  }

  if (username === friendUsername) {
      return res.status(400).json({ message: "You cannot add yourself as a friend." });
  }

  try {
      const user = await User.findOne({ username });
      const friend = await User.findOne({ username: friendUsername });

      if (!user || !friend) {
          return res.status(404).json({ message: "User not found." });
      }

      if (user.friends.includes(friendUsername)) {
          return res.status(400).json({ message: "Already friends." });
      }

      user.friends.push(friendUsername);
      await user.save();

      return res.status(200).json({ message: "Friend added successfully.", friends: user.friends });
  } catch (error) {
      console.error("Error adding friend:", error);
      return res.status(500).json({ message: "Internal server error." });
  }
});

// ✅ Remove a friend
app.post("/friends/remove", async (req, res) => {
  const { username, friendUsername } = req.body;

  if (!username || !friendUsername) {
      return res.status(400).json({ message: "Both usernames are required." });
  }

  try {
      const user = await User.findOne({ username });

      if (!user || !user.friends.includes(friendUsername)) {
          return res.status(404).json({ message: "Friend not found in your list." });
      }

      user.friends = user.friends.filter(f => f !== friendUsername);
      await user.save();

      return res.status(200).json({ message: "Friend removed successfully.", friends: user.friends });
  } catch (error) {
      console.error("Error removing friend:", error);
      return res.status(500).json({ message: "Internal server error." });
  }
});

app.get('/matchHistory/:username', authenticateToken, async (req, res) => {
  const { username } = req.params;

  try {
    const matches = await MatchResult.find({
      'players.username': username,
    }).sort({ createdAt: -1 });

    res.status(200).json(matches);
  } catch (error) {
    console.log("Error fetching match history: " + error);
    console.error('Error fetching match history:', error);
    res.status(500).json({ message: 'Failed to fetch match history' });
  }
});

app.get('/leaderboard', async (req, res) => {
  try {
      let { page = 1, limit = 20, username, language } = req.query;
      page = parseInt(page);
      limit = parseInt(limit);

      if (!language) {
          return res.status(400).json({ message: "Language parameter is required." });
      }

      // Fetch paginated leaderboard, sorting by the selected language's ELO
      const topPlayers = await User.find({
          [`elo.${language}`]: { $exists: true } // Ensure the selected language exists in the ELO map
      })
      .sort({ [`elo.${language}`]: -1 }) // Sort by ELO for the specific language
      .skip((page - 1) * limit) // Pagination logic
      .limit(limit)
      .select(`username elo winStreak`); // Selecting necessary fields

      let userRank = null;
      if (username) {
        const user = await User.findOne({ username }).select(`elo`);
        console.log("Fetched User:", user);
    
        // Use .get() since elo is a Map in MongoDB
        const userElo = user.elo.get(language);  
    
        if (typeof userElo === "number") {
            console.log(`User's ELO for ${language}:`, userElo);
    
            userRank = await User.countDocuments({
                [`elo.${language}`]: { $gt: userElo }
            }) + 1;
    
            console.log(`Calculated user rank:`, userRank);
        } else {
            console.error(`ELO for ${username} in ${language} is missing or invalid.`);
            userRank = null;
        }
    }
    

      res.status(200).json({ leaderboard: topPlayers, userRank });
  } catch (error) {
      console.log("Error fetching leaderboard: " + error);
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
    const language = player1.language; // Use the correct language for matchmaking

    let index = matchmakingQueue.findIndex(player2 => {
      return player2.language === language;
    }); 

    if (index === -1) {
      // No suitable match found, put player1 back in queue
      matchmakingQueue.push(player1);
      continue;
    }

    const player2 = matchmakingQueue.splice(index, 1)[0]; // Remove matched player from queue

    if (player1.username === player2.username) {
      console.log(`[ERROR] Player ${player1.username} tried to match with themselves.`);
      matchmakingQueue.push(player2);
      continue;
    }

    clearTimeout(player1.timeout);
    clearTimeout(player2.timeout);

    const battleId = `${player1.socket.id}-${player2.socket.id}`;

    // Determine difficulty level based on the highest ELO in the match
    let difficultyLevel = 1;
    const highestElo = Math.max(player1.elo[language], player2.elo[language]);
    if (highestElo >= 400) difficultyLevel = 2;
    if (highestElo >= 800) difficultyLevel = 3;
    if (highestElo >= 1200) difficultyLevel = 4;

    function getDifficultyDistribution(baseDifficulty) {
      const random = Math.random(); // Generates a value between 0 and 1
  
      if (random < 0.02) {
          return { main: baseDifficulty, mainCount: 5, extra: baseDifficulty + 1, extraCount: baseDifficulty === 4 ? 2 : 0 }; // Rare challenge mode
      } else if (random < 0.30) {
          return { main: baseDifficulty, mainCount: 3, extra: baseDifficulty + 1, extraCount: baseDifficulty === 4 ? 4 : 2 }; // 3+2 mix, but 3+4 for difficulty 4
      } else if (random < 0.50) {
          return { main: baseDifficulty, mainCount: 4, extra: baseDifficulty + 1, extraCount: baseDifficulty === 4 ? 3 : 1 }; // 4+1 mix, but 4+3 for difficulty 4
      } else {
          return { main: baseDifficulty, mainCount: 5 }; // Standard: 5 from own category
      }
  }

    const { main, mainCount, extra, extraCount } = getDifficultyDistribution(difficultyLevel);

    let questions = await Question.aggregate([
      { $match: { language: language, difficulty: main } },
      { $sample: { size: mainCount } }
    ]);

    if (extra) {
      let extraQuestions = await Question.aggregate([
        { $match: { language: language, difficulty: extra } },
        { $sample: { size: extraCount } }
      ]);
      questions = [...questions, ...extraQuestions];
    }

    // Shuffle the final selection
    questions = questions.sort(() => Math.random() - 0.5);

    if (!questions.length) {
      console.log(`[ERROR] No questions found for language ${language}`);
      continue;
    }

    // **Save match details including questions**
    activeBattles[battleId] = {
      players: [
        { id: player1.socket.id, username: player1.username, elo: player1.elo[language] },
        { id: player2.socket.id, username: player2.username, elo: player2.elo[language] },
      ],
      status: 'active',
      questions: questions.map(q => ({
        question: q.question,
        answers: q.answers,
        type: q.type,
      })),
      language: language,
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
            language: language,
            questions: questions.map(q => ({
              question: q.question,
              answers: q.answers,
              type: q.type,
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
      language: language,
      elo: player1.elo[language],
      opponentElo: player2.elo[language],
      questions, // Send questions
    });

    io.to(player2.socket.id).emit('battleStart', {
      username: player2.username,
      matchId: battleId,
      opponentUsername: player1.username,
      language: language,
      elo: player2.elo[language],
      opponentElo: player1.elo[language],
      questions, // Send questions
    });

    console.log(`[BATTLE STARTED] Sent questions to both players.`);
  }
};



// Handle WebSocket connections
io.on('connection', (socket) => {
  console.log(`[CONNECTED] User connected: ${socket.id}`);

  const matchmakingAttempts = new Map();

  socket.on('joinQueue', async (data) => {
    const { username, language } = data;
    const now = Date.now();

    // ✅ 1️⃣ Rate limit: Allow max 3 matchmaking requests per minute per user
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

    // ✅ 2️⃣ Validate username (empty check)
    if (!username || username.trim().length === 0) {
        console.log(`[ERROR] Empty username attempted matchmaking.`);
        socket.emit('joinQueueError', { message: 'Invalid username. Please set a username in your profile.' });
        return;
    }

    try {
        // ✅ 3️⃣ Fetch user from the database and ensure they exist
        const user = await User.findOne({ username }).lean(); // `.lean()` makes it a plain object

        if (!user) {
            console.log(`[ERROR] User ${username} not found.`);
            socket.emit('joinQueueError', { message: 'User not found. Please log in again.' });
            return;
        }

        console.log(`[CHECK] Language received: ${language}`);
        console.log(`[CHECK] User's ELO before transformation:`, user.elo);

        // ✅ 4️⃣ Ensure ELO is a plain object & enforce required values
        const userElo = user.elo instanceof Map ? Object.fromEntries(user.elo) : user.elo;

        if (!userElo || !userElo.hasOwnProperty(language)) {
            console.log(`[ERROR] User ${username} is missing ELO for language ${language}.`);
            socket.emit('joinQueueError', { message: `Missing ELO for language: ${language}. Please update your profile.` });
            return;
        }

        console.log(`[JOIN QUEUE] Username: ${username}, Language: ${language}, ELO: ${userElo[language]}, Socket ID: ${socket.id}`);

        // ✅ 5️⃣ Remove any existing queue entry for this player before adding them
        matchmakingQueue = matchmakingQueue.filter((p) => p.username !== username);

        // ✅ 6️⃣ Create a player object with correct ELO
        const player = {
            socket,
            username,
            language,
            elo: userElo, // Pass the complete ELO object
            timeout: setTimeout(() => {
                const isStillInQueue = matchmakingQueue.some((p) => p.socket.id === socket.id);
                if (isStillInQueue) {
                    matchmakingQueue = matchmakingQueue.filter((p) => p.socket.id !== socket.id);
                    socket.emit('joinQueueError', { message: 'Matchmaking timeout. Please try again.' });
                    console.log(`[TIMEOUT] Player ${username} (${socket.id}) removed from the queue due to timeout.`);
                }
            }, MATCH_TIMEOUT),
        };

        // ✅ 7️⃣ Add the player to the matchmaking queue
        matchmakingQueue.push(player);
        console.log(`[QUEUE STATUS] Current queue length: ${matchmakingQueue.length}`);

        // ✅ 8️⃣ Attempt to match players
        matchPlayers();
    } catch (error) {
        console.error(`[DATABASE ERROR] Failed to fetch user: ${error}`);
        socket.emit('joinQueueError', { message: 'Server error. Please try again later.' });
    }
  });




  socket.on('playerLeft', async (data) => {
    const { matchId, username } = data;

    console.log(`[PLAYER LEFT] ${username} left the match ${matchId}`);

    if (activeBattles[matchId]) {
        const battle = activeBattles[matchId];
        const leavingPlayer = battle.players.find((p) => p.username === username);
        const remainingPlayer = battle.players.find((p) => p.username !== username);
        const language = battle.language; // Get battle language

        if (leavingPlayer && remainingPlayer) {
            console.log(`[FORFEIT] ${username} forfeited. ${remainingPlayer.username} wins.`);

            // Fetch user data
            const user = await User.findOne({ username: leavingPlayer.username });
            const remainingUser = await User.findOne({ username: remainingPlayer.username });

            if (!user || !remainingUser) {
                console.log(`[ERROR] One of the players could not be found.`);
                return;
            }

            if (!user.elo.has(language) || !remainingUser.elo.has(language)) {
                console.log(`[ERROR] ELO missing for language ${language} for users.`);
                return;
            }

            // Penalize the leaving player in the relevant language
            let newElo = Math.max(0, user.elo.get(language) - 15);
            let newExp = Math.max(0, user.exp - 100);
            let newCoins = Math.max(0, user.coins - 10);
            let newStreak = 0;
            user.elo.set(language, newElo);
            user.exp = newExp;
            user.coins = newCoins;
            user.winStreak = newStreak;
            await user.save();

            // Reward the remaining player in the relevant language
            let newEloWin = remainingUser.elo.get(language) + 15;
            let newExpWin = remainingUser.exp + 100;
            let newCoinsWin = Math.max(0, remainingUser.coins + 40);
            let newWinStreak = remainingUser.winStreak + 1;
            remainingUser.elo.set(language, newEloWin);
            remainingUser.exp = newExpWin;
            remainingUser.coins = newCoinsWin;
            remainingUser.winStreak = newWinStreak;
            await remainingUser.save();

            console.log(`[ELO UPDATE] ${leavingPlayer.username} penalized. New ELO in ${language}: ${newElo}`);
            console.log(`[ELO UPDATE] ${remainingPlayer.username} awarded. New ELO in ${language}: ${newEloWin}, New Win Streak: ${newWinStreak}`);

            // Notify the remaining player
            io.to(remainingPlayer.id).emit('battleEnded', {
                message: 'Opponent left. You win!',
                result: 'playerLeft',
                questions: battle.questions || [],
            });

            // Remove battle from active list
            delete activeBattles[matchId];
        }
    }
  });


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
            const language = battle.language; // Get battle language

            console.log(`[DISCONNECT] Player ${disconnectedPlayer.username} left Battle ID: ${battleId}`);

            // Fetch user data
            const user = await User.findOne({ username: disconnectedPlayer.username });
            const remainingUser = await User.findOne({ username: remainingPlayer.username });

            if (!user || !remainingUser) {
                console.log(`[ERROR] One of the players could not be found.`);
                return;
            }

            if (!user.elo.has(language) || !remainingUser.elo.has(language)) {
                console.log(`[ERROR] ELO missing for language ${language} for users.`);
                return;
            }

            // Penalize disconnected player in the relevant language
            let newElo = Math.max(0, user.elo.get(language) - 15);
            let newExp = Math.max(0, user.exp - 100);
            let newCoins = Math.max(0, user.coins - 10);
            let newStreak = 0;
            user.elo.set(language, newElo);
            user.exp = newExp;
            user.coins = newCoins;
            user.winStreak = newStreak;
            await user.save();

            // Reward the remaining player in the relevant language
            let newEloWin = remainingUser.elo.get(language) + 15;
            let newExpWin = remainingUser.exp + 100;
            let newCoinsWin = Math.max(0, remainingUser.coins + 40);
            let newWinStreak = remainingUser.winStreak + 1;
            remainingUser.elo.set(language, newEloWin);
            remainingUser.exp = newExpWin;
            remainingUser.coins = newCoinsWin;
            remainingUser.winStreak = newWinStreak;
            await remainingUser.save();

            console.log(`[ELO UPDATE] ${disconnectedPlayer.username} penalized. New ELO in ${language}: ${newElo}`);
            console.log(`[ELO UPDATE] ${remainingPlayer.username} awarded. New ELO in ${language}: ${newEloWin}, New Win Streak: ${newWinStreak}`);

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

    console.log(`[SUBMIT RESULTS] Received results from ${username} for match ${matchId} in language ${language}`);

    if (activeBattles[matchId]) {
        const battle = activeBattles[matchId];
        const player = battle.players.find((p) => p.username === username);

        if (player) {
            player.correctAnswers = correctAnswers;

            // Check if both players have submitted their results
            if (battle.players.every((p) => p.correctAnswers !== undefined)) {
                const [player1, player2] = battle.players;
                let winner = null;

                if (player1.correctAnswers > player2.correctAnswers) {
                    winner = player1.username;
                } else if (player2.correctAnswers > player1.correctAnswers) {
                    winner = player2.username;
                }

                // Fetch user profiles
                const user1 = await User.findOne({ username: player1.username });
                const user2 = await User.findOne({ username: player2.username });

                if (!user1 || !user2) {
                    console.log(`[ERROR] One or both users not found in DB.`);
                    return;
                }

                let elo1 = user1.elo.get(language);
                let elo2 = user2.elo.get(language);

                let winStreak1 = user1.winStreak;
                let winStreak2 = user2.winStreak;
                let exp1 = user1.exp;
                let exp2 = user2.exp;
                let coins1 = user1.coins;
                let coins2 = user2.coins;

                // **ELO & XP Handling**
                if (winner === player1.username) {
                    // Player 1 Wins
                    elo1 += 100;
                    elo2 = Math.max(0, elo2 - 15);
                    winStreak1 += 1;
                    winStreak2 = 0;
                    exp1 += 100;
                    exp2 += 10;
                    coins1 += 50;
                    coins2 = Math.max(0, coins2 - 15);
                } else if (winner === player2.username) {
                    // Player 2 Wins
                    elo2 += 100;
                    elo1 = Math.max(0, elo1 - 15);
                    winStreak2 += 1;
                    winStreak1 = 0;
                    exp2 += 100;
                    exp1 += 10;
                    coins2 += 50;
                    coins1 = Math.max(0, coins2 - 15);
                } else {
                    // **Draw Case**
                    console.log(`[DRAW] ${player1.username} vs ${player2.username}`);
                    winStreak1 = 0;
                    winStreak2 = 0;
                    elo1 = Math.max(0, elo1 - 5);
                    elo2 = Math.max(0, elo2 - 5);
                    exp1 += 25;
                    exp2 += 25;
                    coins1 += 25;
                    coins2 += 25;
                }

                // **Update users in DB**
                user1.elo.set(language, elo1);
                user2.elo.set(language, elo2);
                user1.winStreak = winStreak1;
                user2.winStreak = winStreak2;
                user1.exp = exp1;
                user2.exp = exp2;
                user1.coins = coins1;
                user2.coins = coins2;

                await user1.save();
                await user2.save();

                console.log(`[PROFILE UPDATE] ${player1.username} - ELO: ${elo1}, EXP: ${exp1},COINS: ${coins1}, WinStreak: ${winStreak1}`);
                console.log(`[PROFILE UPDATE] ${player2.username} - ELO: ${elo2}, EXP: ${exp2},COINS: ${coins2}, WinStreak: ${winStreak2}`);

                // Notify players
                battle.players.forEach((p) => {
                    io.to(p.id).emit('battleEnded', {
                        message: 'Match finished!',
                        result: {
                            winner: winner || "draw",
                            player1: {
                                username: player1.username,
                                progress: player1.progress,
                                correctAnswers: player1.correctAnswers,
                                elo: elo1,
                                exp: exp1,
                                coins: coins1,
                                winStreak: winStreak1
                            },
                            player2: {
                                username: player2.username,
                                progress: player2.progress,
                                correctAnswers: player2.correctAnswers,
                                elo: elo2,
                                exp: exp2,
                                coins: coins2,
                                winStreak: winStreak2
                            },
                        },
                        questions: battle.questions || [],
                    });
                });

                // Remove match from active battles
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
