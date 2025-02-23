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
  { language: "english", question: "They went to ____ park and ____ together.", answers: ["the", "cafe"] },
  { language: "english", question: "I put my bag ____ the ____ last night.", answers: ["on", "desk"] },
  { language: 'english', question: "She bought a new _____ to wear at the party.", answers: ["dress"] },
  { language: 'english', question: "To unlock ____ door, you need a key.", answers: ["the"] },
  { language: 'english', question: "We saw _____ sun, _____, and _____ in the sky.", answers: ["a", "moon", "star"] },
  { language: "english", question: "He found ____ puppy near his house.", answers: ["a"] },
  { language: "english", question: "They read ____ book at the library today.", answers: ["that"] },
  { language: "english", question: "She placed ____ keys on the table by mistake.", answers: ["her"] },
  { language: "english", question: "We saw ____ car parked on the street last night.", answers: ["this"] },
  { language: "english", question: "I need ____ help with my homework tonight.", answers: ["some"] },
  { language: "english", question: "He forgot ____ phone in the kitchen again.", answers: ["his"] },
  { language: "english", question: "They ate ____ food and drank ____ water at lunch.", answers: ["that", "some"] },
  { language: "english", question: "I left ____ coat and ____ hat in the closet.", answers: ["my", "her"] },
  { language: "english", question: "She gave ____ flowers and ____ card to her friend.", answers: ["these", "that"] },
  { language: "english", question: "We found ____ lost cat, ____ hungry dog, and ____ small bird downtown.", answers: ["that", "this", "a"] },
  { language: 'english', question: "She gazed at the bright _____ in the night sky.", answers: ["star"] },
  { language: 'english', question: "He discovered a tiny _____ in the backyard.", answers: ["bird"] },
  { language: 'english', question: "They set up camp _____ the base of the mountain.", answers: ["at"] },
  { language: 'english', question: "She painted a brilliant _____ in her art class.", answers: ["moon"] },
  { language: 'english', question: "He placed the telescope _____ the tripod.", answers: ["on"] },
  { language: 'english', question: "They glimpsed a comet streaking across the _____.", answers: ["sky"] },
  { language: 'english', question: "The dog napped comfortably _____ the rug.", answers: ["on"] },
  { language: 'english', question: "She found a rare _____ along the beach.", answers: ["pebble"] },
  { language: 'english', question: "He scribbled notes _____ the margin.", answers: ["in"] },
  { language: 'english', question: "The toddler pointed excitedly at the _____ outside the window.", answers: ["tree"] },
  { language: 'english', question: "She quietly closed the _____ behind her.", answers: ["door"] },
  { language: 'english', question: "They installed a bird feeder _____ the balcony.", answers: ["on"] },
  { language: 'english', question: "He finished his meal _____ the table and rushed _____ the door.", answers: ["at", "out"] },
  { language: 'english', question: "She placed her coat _____ the chair and hung her purse _____ the hook.", answers: ["over", "on"] },
  { language: 'english', question: "They woke up _____ dawn and watched the _____ rise over the horizon.", answers: ["at", "sun"] },
  { language: 'english', question: "He pointed _____ the map and traced a route _____ his finger.", answers: ["at", "with"] },
  { language: 'english', question: "She spotted the _____ gliding over the lake and snapped a photo _____ her phone.", answers: ["hawk", "with"] },
  { language: 'english', question: "They chatted _____ the porch and admired the _____ overhead.", answers: ["on", "stars"] },
  { language: 'english', question: "He placed the _____ on the shelf, laid the _____ on the floor, and kicked his boots _____ the corner.", answers: ["book", "bag", "into"] },
  { language: 'english', question: "She found a tiny _____ near the rock, picked it _____ gently, and put it _____ her pocket.", answers: ["shell", "up", "in"] },
  { language: 'english', question: "He gazed at the shimmering _____ in the sky.", answers: ["star"] },
  { language: 'english', question: "She found a wounded _____ under the tree.", answers: ["bird"] },
  { language: 'english', question: "The cat curled up _____ the sofa.", answers: ["on"] },
  { language: 'english', question: "They camped _____ the base of the cliff.", answers: ["at"] },
  { language: 'english', question: "He admired the bright _____ hovering above the horizon.", answers: ["moon"] },
  { language: 'english', question: "She carefully poured coffee _____ the mug.", answers: ["into"] },
  { language: 'english', question: "They watched the graceful _____ soar across the lake.", answers: ["swan"] },
  { language: 'english', question: "He left his umbrella _____ the hallway.", answers: ["in"] },
  { language: 'english', question: "She stored her winter clothes _____ the closet.", answers: ["in"] },
  { language: 'english', question: "He arrived _____ dusk to catch the sunset.", answers: ["at"] },
  { language: 'english', question: "She pinned the photo _____ the bulletin board.", answers: ["to"] },
  { language: 'english', question: "The children built a sandcastle _____ the beach.", answers: ["on"] },
  { language: 'english', question: "They looked _____ the mountain range and pointed _____ the tallest peak.", answers: ["toward", "at"] },
  { language: 'english', question: "He placed the pencil _____ his ear and tucked the paper _____ his pocket.", answers: ["behind", "in"] },
  { language: 'english', question: "She set the telescope _____ the tripod and gazed _____ the constellations.", answers: ["on", "at"] },
  { language: 'english', question: "He heard an owl hooting _____ the forest and walked cautiously _____ the path.", answers: ["in", "along"] },
  { language: 'english', question: "They listened _____ music _____ the radio during the drive.", answers: ["to", "on"] },
  { language: 'english', question: "She scooped flour _____ the jar and measured water _____ the cup.", answers: ["from", "into"] },
  { language: 'english', question: "He placed the _____ on the shelf, dropped his bag _____ the floor, and picked _____ a flashlight.", answers: ["book", "onto", "up"] },
  { language: 'english', question: "She watched the _____ fly across the pond, scribbled notes _____ her journal, and sipped tea _____ her cup.", answers: ["duck", "in", "from"] },
  { language: 'english', question: "She stirred the _____ with a wooden spoon.", answers: ["sauce"] },
  { language: 'english', question: "They admired the colorful _____ on the wall.", answers: ["painting"] },
  { language: 'english', question: "He locked the _____ before leaving.", answers: ["window"] },
  { language: 'english', question: "They replaced the broken _____ in the living room.", answers: ["lamp"] },
  { language: 'english', question: "She lost her favorite _____ at the park.", answers: ["scarf"] },
  { language: 'english', question: "He reviewed the complicated _____ for errors.", answers: ["document"] },
  { language: 'english', question: "They arranged the fresh _____ in a vase.", answers: ["flowers"] },
  { language: 'english', question: "She solved the challenging _____ quickly.", answers: ["puzzle"] },
  { language: 'english', question: "He cooled the hot _____ on the windowsill.", answers: ["pie"] },
  { language: 'english', question: "They purchased a secondhand _____ at the market.", answers: ["bicycle"] },
  { language: 'english', question: "She poured water _____ the glass and set it _____ the tray.", answers: ["into", "on"] },
  { language: 'english', question: "He picked up the package _____ the porch and walked _____ the house.", answers: ["from", "into"] },
  { language: 'english', question: "They wrote notes _____ the chalkboard and erased them _____ a cloth.", answers: ["on", "with"] },
  { language: 'english', question: "She spread butter _____ the bread and placed jam _____ the plate.", answers: ["on", "onto"] },
  { language: 'english', question: "He saved photos _____ the folder and backed them up _____ an external drive.", answers: ["in", "to"] },
  { language: 'english', question: "They stared _____ the bonfire and shared stories _____ each other.", answers: ["at", "with"] },
  { language: 'english', question: "She stuffed the _____ into a bag, locked the door _____ her key, and hurried _____ the taxi.", answers: ["letter", "with", "into"] },
  { language: 'english', question: "They placed the _____ on the counter, covered it _____ a cloth, and handed it _____ the clerk.", answers: ["jar", "with", "to"] },
  { language: 'english', question: "He renovated the _____ in the attic.", answers: ["floorboards"] },
  { language: 'english', question: "She discovered a hidden _____ among the old books.", answers: ["journal"] },
  { language: 'english', question: "They visited the ancient _____ near the river.", answers: ["bridge"] },
  { language: 'english', question: "He polished the wooden _____ after dinner.", answers: ["tray"] },
  { language: 'english', question: "She replaced the broken _____ in the hallway.", answers: ["mirror"] },
  { language: 'english', question: "They enjoyed the scenic _____ from the mountaintop.", answers: ["panorama"] },
  { language: 'english', question: "He wrote an elaborate _____ about his findings.", answers: ["analysis"] },
  { language: 'english', question: "She carefully carried the fragile _____ to the car.", answers: ["figurine"] },
  { language: 'english', question: "They organized the random _____ in the garage.", answers: ["supplies"] },
  { language: 'english', question: "He tested the new _____ in the workshop.", answers: ["device"] },
  { language: 'english', question: "She admired the vibrant _____ in the garden.", answers: ["lilies"] },
  { language: 'english', question: "They rearranged the living room _____ for better space.", answers: ["chairs"] },
  { language: 'english', question: "She prepared the _____ in the kitchen and carried the _____ to the table.", answers: ["ingredients", "platter"] },
  { language: 'english', question: "He discovered a missing _____ under the couch and placed it inside the _____.", answers: ["wallet", "drawer"] },
  { language: 'english', question: "They parked the _____ behind the garage and unloaded the _____ into the shed.", answers: ["truck", "equipment"] },
  { language: 'english', question: "She wrote her _____ on a piece of paper and slipped it into the _____.", answers: ["address", "envelope"] },
  { language: 'english', question: "He sorted the _____ by category and stacked them on the _____.", answers: ["magazines", "rack"] },
  { language: 'english', question: "They brewed fresh _____ every morning and served it in a _____.", answers: ["coffee", "pitcher"] },
  { language: 'english', question: "He peeled the _____ for lunch.", answers: ["orange"] },
  { language: 'english', question: "She opened the _____ to let fresh air in.", answers: ["curtain"] },
  { language: 'english', question: "They rode their _____ through the park.", answers: ["scooter"] },
  { language: 'english', question: "He scribbled notes in his _____.", answers: ["sketchbook"] },
  { language: 'english', question: "She hung the _____ on the wall.", answers: ["poster"] },
  { language: 'english', question: "They cleaned the dusty _____ in the attic.", answers: ["boxes"] },
  { language: 'english', question: "He sprinkled salt on the _____.", answers: ["popcorn"] },
  { language: 'english', question: "She discovered a stray _____ near her porch.", answers: ["kitten"] },
  { language: 'english', question: "They rearranged the _____ in the living room.", answers: ["furniture"] },
  { language: 'english', question: "He replaced the broken _____ in the bathroom.", answers: ["faucet"] },
  { language: 'english', question: "She wore a stylish _____ to the party.", answers: ["dress"] },
  { language: 'english', question: "They wrapped the fragile _____ carefully.", answers: ["vase"] },
  { language: 'english', question: "He placed the _____ on the counter and washed the _____ in the sink.", answers: ["plate", "cup"] },
  { language: 'english', question: "She painted the _____ on the canvas and framed it for the _____.", answers: ["landscape", "exhibit"] },
  { language: 'english', question: "They parked the _____ outside and carried the _____ indoors.", answers: ["car", "groceries"] },
  { language: 'english', question: "He typed his _____ on the computer and saved the _____ to a folder.", answers: ["report", "file"] },
  { language: 'english', question: "She found a note inside the _____ and handed the _____ to her friend.", answers: ["purse", "paper"] },
  { language: 'english', question: "They turned on the _____ for light and placed their _____ on the desk.", answers: ["lantern", "pencils"] },
  { language: 'english', question: "He packed the _____ in his bag, grabbed a _____ for the road, and locked the _____ behind him.", answers: ["tablet", "sandwich", "gate"] },
  { language: 'english', question: "She set the _____ on the table, filled the _____ with water, and offered the _____ a seat.", answers: ["dish", "bowl", "visitor"] },
  


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
