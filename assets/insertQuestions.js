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
  { language: 'english', question: "She braided her _____ before leaving _____ house.", answers: ["hair", "the"] },
  { language: 'english', question: "He used a metal _____ to open the box.", answers: ["knife"] },
  { language: 'english', question: "She watered _____ potted _____ every morning.", answers: ["her", "plants"] },
  { language: 'english', question: "She baked a chocolate _____ for the party.", answers: ["cake"] },
  { language: 'english', question: "He found a lost _____ on the sidewalk.", answers: ["wallet"] },
  { language: 'english', question: "He hammered a _____ into the wall _____ hang a photo.", answers: ["nail", "to"] },
  { language: 'english', question: "She sharpened her _____ before sketching.", answers: ["pencil"] },
  { language: 'english', question: "They lit a scented _____ to create a cozy mood.", answers: ["candle"] },
  { language: 'english', question: "She answered the ringing _____ by the front door.", answers: ["doorbell"] },
  { language: 'english', question: "He unlocked the wooden _____ to enter the backyard.", answers: ["gate"] },
  { language: 'english', question: "She pulled the thick _____ aside to _____ in sunlight.", answers: ["curtain", "let"] },
  { language: 'english', question: "She typed a long _____ to her friend.", answers: ["message"] },
  { language: 'english', question: "They placed fresh _____ on the table _____ decoration.", answers: ["flowers", "for"] },
  { language: 'english', question: "He peeled an _____ for a quick snack.", answers: ["orange"] },
  { language: 'english', question: "They turned on a bright _____ to see in the dark room.", answers: ["lamp"] },
  { language: 'english', question: "He wore his new _____ to the interview.", answers: ["shirt"] },
  { language: 'english', question: "She hung a colorful _____ on the living room wall.", answers: ["painting"] },
  { language: 'english', question: "They folded the soft _____ before placing it _____ the couch.", answers: ["blanket", "on"] },
  { language: 'english', question: "He used a sharp _____ to cut the vegetables.", answers: ["knife"] },
  { language: 'english', question: "She put a red _____ in her lunch box.", answers: ["apple"] },
  { language: 'english', question: "He kicked the _____ across _____ field.", answers: ["ball", "the"] },
  { language: 'english', question: "She opened the _____ to get a fork.", answers: ["drawer"] },
  { language: 'english', question: "They wrote notes on a small _____.", answers: ["paper"] },
  { language: 'english', question: "He read a funny _____.", answers: ["joke"] },
  { language: 'english', question: "He used a _____ to write a letter.", answers: ["pen"] },
  { language: 'english', question: "She walked the _____ in the park.", answers: ["dog"] },
  { language: 'english', question: "They built a big _____ on the beach.", answers: ["sandcastle"] },
  { language: 'english', question: "He wore a warm _____ on his head.", answers: ["hat"] },
  { language: 'english', question: "She drew a pretty _____ with crayons.", answers: ["picture"] },
  { language: 'english', question: "He checked the time on his _____.", answers: ["watch"] },
  { language: 'english', question: "They packed their clothes in a large _____.", answers: ["suitcase"] },
  { language: 'english', question: "She cut a sweet _____ for dessert.", answers: ["cake"] },
  { language: 'english', question: "He locked the _____ behind him.", answers: ["door"] },
  { language: 'english', question: "They used a plastic _____ to feed _____ baby.", answers: ["bottle", "the"] },
  { language: 'english', question: "She put her _____ on the table before dinner.", answers: ["phone"] },
  { language: 'english', question: "He watered his green _____ in the pot.", answers: ["plant"] },
  { language: 'english', question: "They sat _____ the wooden _____ in the park.", answers: ["on","bench"] },
  { language: 'english', question: "He found a shiny _____ on the street.", answers: ["coin"] },
  { language: 'english', question: "They watched a long _____ on television.", answers: ["film"] },
  { language: 'english', question: "She placed a sweet-smelling _____ on the windowsill.", answers: ["candle"] },
  { language: 'english', question: "He listened to loud _____ on his headphones.", answers: ["music"] },
  { language: 'english', question: "She wore a fancy _____ to the wedding.", answers: ["dress"] },
  { language: 'english', question: "He read an exciting _____ .", answers: ["book"] },
  { language: 'english', question: "She polished her silver _____ for the party.", answers: ["ring"] },
  { language: 'english', question: "He used a clean _____ to dry his hands.", answers: ["towel"] },
  { language: 'english', question: "The chicken lays an _____ ", answers: ["egg"] },
  { language: 'english', question: "He put on his _____ before _____ outside.", answers: ["shoes", "going"] },
  { language: 'english', question: "They played a fun _____ with a deck of cards.", answers: ["game"] },
  { language: 'english', question: "He turned the _____ to open the door.", answers: ["knob"] },
  { language: 'english', question: "They sat under a big _____ in the park.", answers: ["tree"] },
  { language: 'english', question: "They took a _____ to _____ nearest store.", answers: ["taxi", "the"] },
  { language: 'english', question: "He filled the small _____ with water _____ the dog.", answers: ["bowl", "for"] },
  { language: 'english', question: "The cat drinks _____", answers: ["milk"] },
  { language: 'english', question: "He rides his _____ to school", answers: ["bike"] },
  { language: 'english', question: "They eat _____ for breakfast", answers: ["cereal"] },
  { language: 'english', question: "She baked fresh _____ for dessert", answers: ["cookies"] },
  { language: 'english', question: "He threw the _____ to his friend", answers: ["ball"] },
  { language: 'english', question: "They opened a jar of _____ for lunch", answers: ["jam"] },
  { language: 'english', question: "He drew a _____ on the board _____ chalk", answers: ["line", "with"] },
  { language: 'english', question: "She peeled a yellow _____ for breakfast.", answers: ["banana"] },
  { language: 'english', question: "He woke up late and rushed down the _____.", answers: ["stairs"] },
  { language: 'english', question: "They washed the dishes in the _____.", answers: ["sink"] },
  { language: 'english', question: "He wore _____ on his hands _____ keep them warm.", answers: ["gloves", "to"] },
  { language: 'english', question: "They used a big _____ to clean the floor.", answers: ["broom"] },
  { language: 'english', question: "She hung her wet _____ outside to dry.", answers: ["laundry"] },
  { language: 'english', question: "They waited _____ the airport with their heavy _____.", answers: ["at","luggage"] },
  { language: 'english', question: "They lit a small _____ to guide them in the dark corridor.", answers: ["torch"] },
  { language: 'english', question: "He filled his _____ with cold water after running.", answers: ["glass"] },
  { language: 'english', question: "She wore a warm _____ around her neck.", answers: ["scarf"] },
  { language: 'english', question: "He unlocked his phone with a _____ .", answers: ["passcode"] },
  { language: 'english', question: "He placed his _____ on the desk to check emails.", answers: ["laptop"] },
  { language: 'english', question: "They used a stiff _____ to clean _____ shoes.", answers: ["brush", "the"] },
  { language: 'english', question: "She took a bright _____ to label her boxes.", answers: ["marker"] },
  { language: 'english', question: "He offered a piece of _____ to his friend _____ chew.", answers: ["gum", "to"] },
  { language: 'english', question: "He wore a _____ while riding his scooter.", answers: ["helmet"] },
  { language: 'english', question: "They sprinkled salt on the fresh _____ .", answers: ["fries"] },
  { language: 'english', question: "He placed a soft _____ on the wooden chair.", answers: ["cushion"] },
  { language: 'english', question: "He sliced fresh _____ for breakfast.", answers: ["bread"] },
  { language: 'english', question: "She held a colorful _____ over her head in the rain.", answers: ["umbrella"] },
  { language: 'english', question: "They planted some _____ in the garden _____ herbs.", answers: ["seeds", "for"] },
  { language: 'english', question: "He turned up the _____ to hear the music better.", answers: ["stereo"] },
  { language: 'english', question: "He placed his new _____ in the drawer for safekeeping.", answers: ["keys"] },
  { language: 'english', question: "She turned on the _____ to boil water _____ tea.", answers: ["stove", "for"] },
  { language: 'english', question: "They used a large _____ to carry the dishes.", answers: ["tray"] },
  { language: 'english', question: "He _____ the groceries into the _____ to keep them cold.", answers: ["put", "fridge"] },
  { language: 'english', question: "She used a _____ to change _____ TV channel.", answers: ["remote", "the"] },
  { language: 'english', question: "He typed on the _____ to send _____ email.", answers: ["keyboard", "an"] },
  { language: 'english', question: "They changed the _____ on the bed each week.", answers: ["sheets"] },
  { language: 'english', question: "He wore tough _____ while digging _____ the garden.", answers: ["boots", "in"] },
  { language: 'english', question: "They placed a cozy _____ on the sofa for extra comfort.", answers: ["pillow"] },
  { language: 'english', question: "She wore a protective _____ over her face.", answers: ["mask"] },
  { language: 'english', question: "He tied the cooking _____ around his waist before baking.", answers: ["apron"] },
  { language: 'english', question: "He received a printed _____ at the grocery store.", answers: ["receipt"] },
  { language: 'english', question: "They saved a discount _____ for their next purchase.", answers: ["coupon"] },
  { language: 'english', question: "She wore cozy _____ at home _____ keep her feet warm.", answers: ["slippers", "to"] },
  { language: 'english', question: "He plugged his phone into the _____ near the bed.", answers: ["charger"] },
  { language: 'english', question: "They placed a new _____ outside the front door.", answers: ["doormat"] },
  { language: 'english', question: "She sipped her drink through a colorful _____.", answers: ["straw"] },
  { language: 'english', question: "He placed his cup on a round _____ to protect the table.", answers: ["coaster"] },
  { language: 'english', question: "She checked her temperature with a digital _____.", answers: ["thermometer"] },
  { language: 'english', question: "He warmed the leftovers in the _____.", answers: ["microwave"] },
  { language: 'english', question: "He toasted two slices of bread in the _____.", answers: ["toaster"] },
  { language: 'english', question: "He used a bicycle _____ to fill the tires with air.", answers: ["pump"] },
  { language: 'english', question: "He used a heavy _____ to fix the loose nail.", answers: ["hammer"] },
  { language: 'english', question: "They dug a small hole with a _____ to plant _____ tree.", answers: ["shovel", "the"] },
  { language: 'english', question: "He fried the eggs in a hot _____ .", answers: ["pan"] },
  { language: 'english', question: "They baked fresh cookies in the _____ .", answers: ["oven"] },
  { language: 'english', question: "She put the phone charger into the wall _____ .", answers: ["plug"] },
  { language: 'english', question: "They bought a new _____ for the TV remote.", answers: ["battery"] },
  { language: 'english', question: "He turned on the _____ to listen to music.", answers: ["speaker"] },
  { language: 'english', question: "He hung a funny _____ on the fridge door.", answers: ["magnet"] },
  { language: 'english', question: "They used strong _____ to fix the broken handle.", answers: ["glue"] },
  { language: 'english', question: "She found an old wooden _____ in the attic.", answers: ["chest"] },
  { language: 'english', question: "He closed the window to block the strong _____.", answers: ["wind"] },
  { language: 'english', question: "They watched the _____ flow .", answers: ["river"] },
  { language: 'english', question: "They felt the cool _____ blow across the open field.", answers: ["breeze"] },
  { language: 'english', question: "He used a small _____ to measure flour.", answers: ["scale"] },
  { language: 'english', question: "She wrote her thoughts in a secret _____.", answers: ["diary"] },
  { language: 'english', question: "They set up a large _____ at the campsite.", answers: ["tent"] },
  { language: 'english', question: "She admired the colorful _____ in the morning sky.", answers: ["sunrise"] },
  { language: 'english', question: "They built a small _____ with wooden planks.", answers: ["shed"] },
  { language: 'english', question: "He stored his fishing gear in a large _____.", answers: ["crate"] },
  { language: 'english', question: "She squeezed fresh _____ for breakfast.", answers: ["lemons"] },
  { language: 'english', question: "They saw a gentle _____ in the barn.", answers: ["horse"] },
  { language: 'english', question: "He touched the soft _____ near the water.", answers: ["moss"] },
  { language: 'english', question: "She wore a pretty _____ in her hair.", answers: ["bow"] },
  { language: 'english', question: "He drank a cold glass of citrus _____ after his run.", answers: ["lemonade"] },
  { language: 'english', question: "She stored her winter _____ under the bed.", answers: ["coats"] },
  { language: 'english', question: "He used a strong _____ to tie the boxes.", answers: ["rope"] },
  { language: 'english', question: "She grabbed a warm _____ before stepping _____.", answers: ["coat", "out"] },
  { language: 'english', question: "He picked a soft _____ and placed it _____ his shoulders.", answers: ["scarf", "around"] },
  { language: 'english', question: "She packed a small _____ for her trip.", answers: ["bag"] },
  { language: 'english', question: "He placed a fresh _____ on the dining table.", answers: ["napkin"] },
  { language: 'english', question: "They played outside and sat on the green _____.", answers: ["grass"] },
  { language: 'english', question: "She filled a large _____ with warm water.", answers: ["bucket"] },
  { language: 'english', question: "He grabbed his _____ before walking out.", answers: ["keys"] },
  { language: 'english', question: "She opened the _____ to let in fresh air.", answers: ["window"] },
  { language: 'english', question: "They set up a new _____ for their computer.", answers: ["monitor"] },
  { language: 'english', question: "She lit a small _____ in the evening.", answers: ["candle"] },
  { language: 'english', question: "They baked fresh _____ in the oven.", answers: ["bread"] },
  { language: 'english', question: "He put on his _____ before leaving _____ house.", answers: ["hat", "the"] },
  { language: 'english', question: "She placed a small _____ in the vase _____ decoration.", answers: ["flower", "for"] },
  { language: 'english', question: "He placed his _____ on the chair before sitting.", answers: ["backpack"] },
  { language: 'english', question: "She tied a thick _____ around her waist.", answers: ["belt"] },
  { language: 'english', question: "They took a _____ to the train station.", answers: ["bus"] },
  { language: 'english', question: "He placed a fresh _____ on the pillow.", answers: ["cover"] },
  { language: 'english', question: "He turned on the _____ to hear some music.", answers: ["radio"] },
  { language: 'english', question: "She wore a thick _____ to keep warm.", answers: ["sweater"] },
  { language: 'english', question: "He placed the dirty _____ into the sink.", answers: ["plate"] },
  { language: 'english', question: "He heard the sound of distant _____ before the storm.", answers: ["thunder"] },
  { language: 'english', question: "The morning _____ covered the fields.", answers: ["fog"] },
  { language: 'english', question: "She jumped into a small _____ after the rain.", answers: ["puddle"] },
  { language: 'english', question: "They watched a _____ launch into space.", answers: ["rocket"] },
  { language: 'english', question: "He waited for the _____ to arrive at the station.", answers: ["train"] },
  { language: 'english', question: "A cool _____ blew through the open window.", answers: ["breeze"] },
  { language: 'english', question: "Her voice created an _____ in the empty hallway.", answers: ["echo"] },
  { language: 'english', question: "The referee blew the _____ to start the game.", answers: ["whistle"] },
  { language: 'english', question: "He adjusted the _____ on the boat before setting off.", answers: ["sail"] },
  { language: 'english', question: "They walked along the _____, collecting seashells.", answers: ["shore"] },
  { language: 'english', question: "From the hill, they could see the entire _____ below.", answers: ["valley"] },
  { language: 'english', question: "Many boats were docked at the _____.", answers: ["harbor"] },
  { language: 'english', question: "He stood at the edge of the _____ and looked down.", answers: ["cliff"] },
  { language: 'english', question: "The explorers entered the dark _____ with flashlights.", answers: ["cave"] },
  { language: 'english', question: "The workers arrived early at the _____.", answers: ["factory"] },
  { language: 'english', question: "The crowd cheered inside the huge _____.", answers: ["stadium"] },
  { language: 'english', question: "Colorful _____ lit up the night sky.", answers: ["fireworks"] },
  { language: 'english', question: "People lined the streets to watch the _____.", answers: ["parade"] },
  { language: 'english', question: "A bright light shined from the tall _____.", answers: ["lighthouse"] },
  { language: 'english', question: "The pilot flew the _____ _____ the clouds.", answers: ["airplane", "above"] },
  { language: 'english', question: "They floated their wooden _____ below the bridge.", answers: ["raft"] },
  { language: 'english', question: "She parked her _____ _____ the house.", answers: ["motorcycle", "beside"] },
  { language: 'english', question: "They set up their _____ _____ the campsite.", answers: ["caravan", "near"] },
  { language: 'english', question: "The submarine moved slowly _____ the current.", answers: ["against"] },
  { language: 'english', question: "The rescue team flew a _____ _____ the river.", answers: ["helicopter", "across"] },
  { language: 'english', question: "He leaned his _____ _____ the wall after riding it.", answers: ["bicycle", "on"] },
  { language: 'english', question: "A beautiful _____ appeared _____ the clouds.", answers: ["rainbow", "inside"] },
  { language: 'english', question: "She watched the _____ shine _____ the window.", answers: ["moonlight", "outside"] },
  { language: 'english', question: "The wide _____ flowed down the landscape.", answers: ["river"] },
  { language: 'english', question: "A white _____ floated across the blue sky.", answers: ["cloud"] },
  { language: 'english', question: "He saw his _____ move on the ground in the sunlight.", answers: ["shadow"] },
  { language: 'english', question: "They climbed to the top of the green _____.", answers: ["hill"] },
  { language: 'english', question: "She planted flowers in her _____.", answers: ["garden"] },
  { language: 'english', question: "A yellow _____ fell from the tree.", answers: ["leaf"] },
  { language: 'english', question: "The bird built a cozy _____ in the tree.", answers: ["nest"] },
  { language: 'english', question: "She broke a small _____ from the tree.", answers: ["branch"] },
  { language: 'english', question: "He picked up a smooth _____ from the ground.", answers: ["stone"] },
  { language: 'english', question: "They walked along the narrow _____.", answers: ["path"] },
  { language: 'english', question: "A long _____ connected the two sides of the river.", answers: ["bridge"] },
  { language: 'english', question: "The tall _____ stood in the middle of the city.", answers: ["tower"] },
  { language: 'english', question: "She looked out of the _____ to see the street.", answers: ["window"] },
  { language: 'english', question: "He looked at himself in the _____.", answers: ["mirror"] },
  { language: 'english', question: "She heard a soft _____ in the quiet room.", answers: ["whisper"] },
  { language: 'english', question: "His _____ was fast after running up the stairs.", answers: ["heartbeat"] },
  { language: 'english', question: "A large _____ crashed against the shore.", answers: ["wave"] },
  { language: 'english', question: "A small _____ fell on his hand from the sky.", answers: ["raindrop"] },
  { language: 'english', question: "She saw her _____ in the water.", answers: ["reflection"] },
  { language: 'english', question: "They walked carefully on the wet _____.", answers: ["pavement"] },
  { language: 'english', question: "Children played on the swings in the _____.", answers: ["playground"] },
  { language: 'english', question: "They placed the _____ _____ the two chairs.", answers: ["table", "between"] },
  { language: 'english', question: "They walked _____ the river on a small path.", answers: ["along"] },
  { language: 'english', question: "She sat _____ her best friend at the picnic.", answers: ["beside"] },
  { language: 'english', question: "He placed his keys _____ his pocket.", answers: ["inside"] },
  { language: 'english', question: "They built a playground _____ the school.", answers: ["near"] },
  { language: 'english', question: "The wind blew _____ the trees.", answers: ["through"] },
  { language: 'english', question: "He leaned _____ the wall while waiting.", answers: ["against"] },
  { language: 'english', question: "The mountains stretched _____ the horizon.", answers: ["beyond"] },
  { language: 'english', question: "The _____ painted the sky with orange and pink.", answers: ["sunset"] },
  { language: 'english', question: "Morning _____ covered the grass.", answers: ["dew"] },
  { language: 'english', question: "Thick _____ made it hard to see the road.", answers: ["fog"] },
  { language: 'english', question: "The strong _____ knocked over some trees.", answers: ["storm"] },
  { language: 'english', question: "A loud clap of _____ shook the house.", answers: ["thunder"] },
  { language: 'english', question: "Pieces of _____ fell from the sky during the storm.", answers: ["hail"] },
  { language: 'english', question: "Each _____ looked unique and delicate.", answers: ["snowflake"] },
  { language: 'english', question: "The hot _____ stretched for miles with no trees.", answers: ["desert"] },
  { language: 'english', question: "The crocodile hid in the muddy _____.", answers: ["swamp"] },
  { language: 'english', question: "They admired the tall _____ as water rushed down.", answers: ["waterfall"] },
  { language: 'english', question: "A dark _____ led through the mountain.", answers: ["tunnel"] },
  { language: 'english', question: "The ancient _____ stood in the middle of the ruins.", answers: ["arch"] },
  { language: 'english', question: "The building was supported by a large _____.", answers: ["pillar"] },
  { language: 'english', question: "The _____ of the king stood in the square.", answers: ["statue"] },
  
  
  



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
