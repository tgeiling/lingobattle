require('dotenv').config();
const mongoose = require('mongoose');

// Define the Question schema
const QuestionSchema = new mongoose.Schema({
  language: { type: String, required: true },
  question: { type: String, required: true },
  answers: { type: [String], required: true },
});

// Create the model
const Question = mongoose.model('Question', QuestionSchema);

// MongoDB connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

const sampleQuestions = [
  // English
  { language: 'english', question: "A _____ can fly, but a penguin cannot.", answers: ["bird"] },
  { language: 'english', question: "The _____ barked loudly at the mailman.", answers: ["dog"] },
  { language: 'english', question: "I _____ a sandwich for lunch yesterday.", answers: ["ate"] },
  { language: 'english', question: "She bought a new _____ to wear at the party.", answers: ["dress"] },
  { language: 'english', question: "To unlock the door, you need a _____.", answers: ["key"] },

  // German
  { language: 'german', question: "Ein _____ kann fliegen, aber ein Pinguin nicht.", answers: ["Vogel"] },
  { language: 'german', question: "Der _____ bellte laut den Postboten an.", answers: ["Hund"] },
  { language: 'german', question: "Ich _____ gestern ein Sandwich zum Mittagessen.", answers: ["aß"] },
  { language: 'german', question: "Sie kaufte ein neues _____ für die Party.", answers: ["Kleid"] },
  { language: 'german', question: "Um die Tür zu öffnen, brauchst du einen _____.", answers: ["Schlüssel"] },

  // Spanish
  { language: 'spanish', question: "Un _____ puede volar, pero un pingüino no puede.", answers: ["pájaro"] },
  { language: 'spanish', question: "El _____ ladró fuerte al cartero.", answers: ["perro"] },
  { language: 'spanish', question: "Yo _____ un sándwich para el almuerzo ayer.", answers: ["comí"] },
  { language: 'spanish', question: "Ella compró un nuevo _____ para usar en la fiesta.", answers: ["vestido"] },
  { language: 'spanish', question: "Para abrir la puerta, necesitas una _____.", answers: ["llave"] },

  // Swiss German
  { language: 'swiss', question: "E _____ cha flüge, aber e Pinguin nid.", answers: ["Vogel"] },
  { language: 'swiss', question: "Dr _____ hät laut de Briefträger averbellt.", answers: ["Hund"] },
  { language: 'swiss', question: "Ich _____ geschter es Sandwich zum Zmittag.", answers: ["ha gässe"] },
  { language: 'swiss', question: "Si hät es nöis _____ fürs Fäscht kauft.", answers: ["Chleid"] },
  { language: 'swiss', question: "Um d’Türe z’öffne, bruuchsch en _____.", answers: ["Schlüssel"] },

  // Dutch
  { language: 'dutch', question: "Een _____ kan vliegen, maar een pinguïn niet.", answers: ["vogel"] },
  { language: 'dutch', question: "De _____ blafte hard naar de postbode.", answers: ["hond"] },
  { language: 'dutch', question: "Ik _____ gisteren een sandwich als lunch.", answers: ["at"] },
  { language: 'dutch', question: "Ze kocht een nieuwe _____ om naar het feest te dragen.", answers: ["jurk"] },
  { language: 'dutch', question: "Om de deur te openen, heb je een _____ nodig.", answers: ["sleutel"] },
];

// Function to reset and insert questions
const resetAndInsertQuestions = async () => {
  try {
    console.log('🗑️ Dropping "questions" collection...');
    await Question.deleteMany({});
    console.log('✅ "questions" collection dropped.');

    await Question.insertMany(sampleQuestions);
    console.log(`✅ Successfully inserted ${sampleQuestions.length} questions.`);

  } catch (error) {
    console.error('❌ Error inserting questions:', error);
  } finally {
    mongoose.connection.close();
  }
};

// Execute the function
resetAndInsertQuestions();
