import 'package:flutter/material.dart';

class MultiplayerQuestion {
  final String question;
  final List<String> answers;

  MultiplayerQuestion({
    required this.question,
    required this.answers,
  });

  factory MultiplayerQuestion.fromJson(Map<String, dynamic> json) {
    return MultiplayerQuestion(
      question: json['question'],
      answers: List<String>.from(json['answers']), // Ensure list of strings
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answers': answers,
    };
  }
}

class MultiplayerQuestionsPool {
  static final Map<String, List<MultiplayerQuestion>> questionsByLanguage = {
    'english': [
      MultiplayerQuestion(
        question: "A _____ can fly, but a penguin cannot.",
        answers: ["bird"],
      ),
      MultiplayerQuestion(
        question: "The _____ barked loudly at the mailman.",
        answers: ["dog"],
      ),
      MultiplayerQuestion(
        question: "I _____ a sandwich for lunch yesterday.",
        answers: ["ate"],
      ),
      MultiplayerQuestion(
        question: "She bought a new _____ to wear at the party.",
        answers: ["dress"],
      ),
      MultiplayerQuestion(
        question: "To unlock the door, you need a _____.",
        answers: ["key"],
      ),
      MultiplayerQuestion(
        question: "I saw a _____ in the sky during the thunderstorm.",
        answers: ["lightning"],
      ),
      MultiplayerQuestion(
        question: "Please _____ the window before it starts raining.",
        answers: ["close"],
      ),
      MultiplayerQuestion(
        question: "The baby loves to play with a colorful _____.",
        answers: ["ball"],
      ),
      MultiplayerQuestion(
        question: "They _____ to the park every weekend to relax.",
        answers: ["go"],
      ),
      MultiplayerQuestion(
        question: "The _____ was sweet and juicy, just like summer.",
        answers: ["fruit"],
      ),
      MultiplayerQuestion(
        question: "The _____ is shining, and the sky is _____ today.",
        answers: ["sun", "blue"],
      ),
      MultiplayerQuestion(
        question: "I _____ my homework _____ going to bed.",
        answers: ["finished", "before"],
      ),
      MultiplayerQuestion(
        question: "She put the book _____ the table and _____ the room.",
        answers: ["on", "left"],
      ),
      MultiplayerQuestion(
        question: "The _____ was very _____, so we decided to buy it.",
        answers: ["cake", "delicious"],
      ),
      MultiplayerQuestion(
        question: "They _____ in the garden and _____ some flowers.",
        answers: ["worked", "planted"],
      ),
      MultiplayerQuestion(
        question: "To make a sandwich, you need _____, _____, and _____.",
        answers: ["bread", "butter", "cheese"],
      ),
      MultiplayerQuestion(
        question: "The children _____ outside because it was _____ and sunny.",
        answers: ["played", "warm"],
      ),
      MultiplayerQuestion(
        question: "I can't find my _____, can you check in the _____?",
        answers: ["phone", "kitchen"],
      ),
      MultiplayerQuestion(
        question: "The _____ jumped over the _____ to get into the field.",
        answers: ["cow", "fence"],
      ),
      MultiplayerQuestion(
        question: "If you mix _____ and _____, you get purple.",
        answers: ["red", "blue"],
      ),
      MultiplayerQuestion(
        question: "The cat chased the _____ across the _____.",
        answers: ["mouse", "yard"],
      ),
      MultiplayerQuestion(
        question: "We _____ a sandcastle at the _____ yesterday.",
        answers: ["built", "beach"],
      ),
      MultiplayerQuestion(
        question: "The _____ opened the window and let the _____ inside.",
        answers: ["child", "air"],
      ),
      MultiplayerQuestion(
        question: "The _____ is too _____ to lift on my own.",
        answers: ["box", "heavy"],
      ),
      MultiplayerQuestion(
        question: "Can you pass me the _____, _____, and _____ for the salad?",
        answers: ["tomatoes", "cucumber", "lettuce"],
      ),
      MultiplayerQuestion(
        question: "He _____ the ball, but it _____ over the fence.",
        answers: ["kicked", "flew"],
      ),
      MultiplayerQuestion(
        question: "The stars are shining so _____ in the _____ tonight.",
        answers: ["brightly", "sky"],
      ),
      MultiplayerQuestion(
        question: "Please write your name _____ and _____ on the form.",
        answers: ["first", "last"],
      ),
      MultiplayerQuestion(
        question: "I _____ a new book about _____ and finished it in one day.",
        answers: ["read", "adventure"],
      ),
      MultiplayerQuestion(
        question: "The _____ was baking bread while the _____ made soup.",
        answers: ["baker", "chef"],
      ),
      MultiplayerQuestion(
        question: "The _____ fell off the table and broke.",
        answers: ["glass"],
      ),
      MultiplayerQuestion(
        question: "The _____ in the park sang beautifully this morning.",
        answers: ["bird"],
      ),
      MultiplayerQuestion(
        question: "The room was so dark, I turned on the _____.",
        answers: ["light"],
      ),
      MultiplayerQuestion(
        question: "To bake a cake, you need flour, eggs, and _____.",
        answers: ["sugar"],
      ),
      MultiplayerQuestion(
        question: "The dog wagged its _____ when it saw its owner.",
        answers: ["tail"],
      ),
      MultiplayerQuestion(
        question: "The train arrived at the _____ five minutes late.",
        answers: ["station"],
      ),
      MultiplayerQuestion(
        question: "The teacher wrote the lesson on the _____.",
        answers: ["board"],
      ),
      MultiplayerQuestion(
        question: "The baby held the _____ tightly in her hands.",
        answers: ["toy"],
      ),
      MultiplayerQuestion(
        question: "The flowers in the garden smelled like _____.",
        answers: ["roses"],
      ),
      MultiplayerQuestion(
        question: "The _____ blew all the leaves off the trees.",
        answers: ["wind"],
      ),
      MultiplayerQuestion(
        question: "The _____ stopped working because it ran out of batteries.",
        answers: ["clock"],
      ),
      MultiplayerQuestion(
        question: "The soup was too hot, so I waited for it to _____.",
        answers: ["cool"],
      ),
      MultiplayerQuestion(
        question: "The little boy lost his _____ while playing outside.",
        answers: ["hat"],
      ),
      MultiplayerQuestion(
        question: "She opened the _____ to take out a glass of water.",
        answers: ["fridge"],
      ),
      MultiplayerQuestion(
        question: "The _____ buzzed around the flowers in the garden.",
        answers: ["bee"],
      ),
      MultiplayerQuestion(
        question: "I need to buy a new _____ because mine is too old to use.",
        answers: ["phone"],
      ),
      MultiplayerQuestion(
        question: "The _____ barked loudly to scare away the stranger.",
        answers: ["dog"],
      ),
      MultiplayerQuestion(
        question: "The _____ in the sky was shining bright all night.",
        answers: ["moon"],
      ),
      MultiplayerQuestion(
        question: "The child colored the picture with a red _____.",
        answers: ["crayon"],
      ),
      MultiplayerQuestion(
        question: "The _____ carried the apples in a wooden basket.",
        answers: ["farmer"],
      ),
    ],
    'spanish': [
      MultiplayerQuestion(
        question: "Un _____ puede volar, pero un pingüino no puede.",
        answers: ["pájaro"],
      ),
      MultiplayerQuestion(
        question: "El _____ ladró fuerte al cartero.",
        answers: ["perro"],
      ),
      MultiplayerQuestion(
        question: "Yo _____ un sándwich para el almuerzo ayer.",
        answers: ["comí"],
      ),
      MultiplayerQuestion(
        question: "Ella compró un nuevo _____ para usar en la fiesta.",
        answers: ["vestido"],
      ),
      MultiplayerQuestion(
        question: "Para abrir la puerta, necesitas una _____.",
        answers: ["llave"],
      ),
      MultiplayerQuestion(
        question: "Vi un _____ en el cielo durante la tormenta.",
        answers: ["rayo"],
      ),
      MultiplayerQuestion(
        question: "Por favor _____ la ventana antes de que empiece a llover.",
        answers: ["cierra"],
      ),
      MultiplayerQuestion(
        question: "Al bebé le encanta jugar con una _____ colorida.",
        answers: ["pelota"],
      ),
      MultiplayerQuestion(
        question: "Ellos _____ al parque cada fin de semana para relajarse.",
        answers: ["van"],
      ),
      MultiplayerQuestion(
        question: "La _____ estaba dulce y jugosa, como el verano.",
        answers: ["fruta"],
      ),
      MultiplayerQuestion(
        question: "El _____ está brillando, y el cielo está _____ hoy.",
        answers: ["sol", "azul"],
      ),
      MultiplayerQuestion(
        question: "Yo _____ mi tarea _____ de irme a dormir.",
        answers: ["terminé", "antes"],
      ),
      MultiplayerQuestion(
        question: "Ella puso el libro _____ la mesa y _____ la habitación.",
        answers: ["sobre", "salió"],
      ),
      MultiplayerQuestion(
        question: "El _____ era muy _____, así que decidimos comprarlo.",
        answers: ["pastel", "delicioso"],
      ),
      MultiplayerQuestion(
        question: "Ellos _____ en el jardín y _____ algunas flores.",
        answers: ["trabajaron", "plantaron"],
      ),
      MultiplayerQuestion(
        question: "Para hacer un sándwich, necesitas _____, _____ y _____.",
        answers: ["pan", "mantequilla", "queso"],
      ),
      MultiplayerQuestion(
        question: "Los niños _____ afuera porque hacía _____ y sol.",
        answers: ["jugaron", "calor"],
      ),
      MultiplayerQuestion(
        question: "No encuentro mi _____, ¿puedes revisar en la _____?",
        answers: ["teléfono", "cocina"],
      ),
      MultiplayerQuestion(
        question: "La _____ saltó sobre la _____ para entrar al campo.",
        answers: ["vaca", "cerca"],
      ),
      MultiplayerQuestion(
        question: "Si mezclas _____ y _____, obtienes morado.",
        answers: ["rojo", "azul"],
      ),
      MultiplayerQuestion(
        question: "El gato persiguió al _____ por todo el _____.",
        answers: ["ratón", "patio"],
      ),
      MultiplayerQuestion(
        question: "Nosotros _____ un castillo de arena en la _____ ayer.",
        answers: ["hicimos", "playa"],
      ),
      MultiplayerQuestion(
        question: "El _____ abrió la ventana y dejó entrar el _____.",
        answers: ["niño", "aire"],
      ),
      MultiplayerQuestion(
        question: "La _____ es demasiado _____ para levantarla solo.",
        answers: ["caja", "pesada"],
      ),
      MultiplayerQuestion(
        question: "¿Puedes pasarme los _____, _____ y _____ para la ensalada?",
        answers: ["tomates", "pepino", "lechuga"],
      ),
      MultiplayerQuestion(
        question: "Él _____ la pelota, pero _____ por encima de la cerca.",
        answers: ["pateó", "voló"],
      ),
      MultiplayerQuestion(
        question: "Las estrellas brillan tan _____ en el _____ esta noche.",
        answers: ["brillante", "cielo"],
      ),
      MultiplayerQuestion(
        question: "Por favor escribe tu nombre _____ y _____ en el formulario.",
        answers: ["primero", "último"],
      ),
      MultiplayerQuestion(
        question: "Yo _____ un nuevo libro sobre _____ y lo terminé en un día.",
        answers: ["leí", "aventura"],
      ),
      MultiplayerQuestion(
        question: "El _____ horneaba pan mientras el _____ hacía sopa.",
        answers: ["panadero", "chef"],
      ),
      MultiplayerQuestion(
        question: "El _____ se cayó de la mesa y se rompió.",
        answers: ["vaso"],
      ),
      MultiplayerQuestion(
        question: "El _____ en el parque cantó hermosamente esta mañana.",
        answers: ["pájaro"],
      ),
      MultiplayerQuestion(
        question: "La habitación estaba tan oscura que encendí la _____.",
        answers: ["luz"],
      ),
      MultiplayerQuestion(
        question: "Para hornear un pastel necesitas harina, huevos y _____.",
        answers: ["azúcar"],
      ),
      MultiplayerQuestion(
        question: "El perro movió la _____ cuando vio a su dueño.",
        answers: ["cola"],
      ),
      MultiplayerQuestion(
        question: "El tren llegó a la _____ cinco minutos tarde.",
        answers: ["estación"],
      ),
      MultiplayerQuestion(
        question: "El maestro escribió la lección en el _____.",
        answers: ["pizarrón"],
      ),
      MultiplayerQuestion(
        question: "El bebé sostuvo el _____ con fuerza en sus manos.",
        answers: ["juguete"],
      ),
      MultiplayerQuestion(
        question: "Las flores en el jardín olían a _____.",
        answers: ["rosas"],
      ),
      MultiplayerQuestion(
        question: "El _____ sopló todas las hojas de los árboles.",
        answers: ["viento"],
      ),
      MultiplayerQuestion(
        question: "El _____ dejó de funcionar porque se quedó sin baterías.",
        answers: ["reloj"],
      ),
      MultiplayerQuestion(
        question:
            "La sopa estaba demasiado caliente, así que esperé a que _____.",
        answers: ["enfriara"],
      ),
      MultiplayerQuestion(
        question: "El niño pequeño perdió su _____ mientras jugaba afuera.",
        answers: ["sombrero"],
      ),
      MultiplayerQuestion(
        question: "Ella abrió el _____ para sacar un vaso de agua.",
        answers: ["refrigerador"],
      ),
      MultiplayerQuestion(
        question: "La _____ zumbó alrededor de las flores en el jardín.",
        answers: ["abeja"],
      ),
      MultiplayerQuestion(
        question: "Necesito comprar un nuevo _____ porque el mío es muy viejo.",
        answers: ["teléfono"],
      ),
      MultiplayerQuestion(
        question: "El _____ ladró fuerte para asustar al extraño.",
        answers: ["perro"],
      ),
      MultiplayerQuestion(
        question: "La _____ en el cielo brillaba toda la noche.",
        answers: ["luna"],
      ),
      MultiplayerQuestion(
        question: "El niño coloreó la imagen con un _____ rojo.",
        answers: ["crayón"],
      ),
      MultiplayerQuestion(
        question: "El _____ llevó las manzanas en una canasta de madera.",
        answers: ["granjero"],
      ),
    ],
    'dutch': [
      MultiplayerQuestion(
        question: "Een _____ kan vliegen, maar een pinguïn niet.",
        answers: ["vogel"],
      ),
      MultiplayerQuestion(
        question: "De _____ blafte hard naar de postbode.",
        answers: ["hond"],
      ),
      MultiplayerQuestion(
        question: "Ik _____ gisteren een sandwich als lunch.",
        answers: ["at"],
      ),
      MultiplayerQuestion(
        question: "Ze kocht een nieuwe _____ om naar het feest te dragen.",
        answers: ["jurk"],
      ),
      MultiplayerQuestion(
        question: "Om de deur te openen, heb je een _____ nodig.",
        answers: ["sleutel"],
      ),
      MultiplayerQuestion(
        question: "Ik zag een _____ in de lucht tijdens het onweer.",
        answers: ["bliksem"],
      ),
      MultiplayerQuestion(
        question: "Sluit alsjeblieft het _____ voordat het begint te regenen.",
        answers: ["raam"],
      ),
      MultiplayerQuestion(
        question: "De baby speelt graag met een kleurrijke _____.",
        answers: ["bal"],
      ),
      MultiplayerQuestion(
        question: "Ze _____ elk weekend naar het park om te ontspannen.",
        answers: ["gaan"],
      ),
      MultiplayerQuestion(
        question: "De _____ was zoet en sappig, net als de zomer.",
        answers: ["fruit"],
      ),
      MultiplayerQuestion(
        question: "De _____ schijnt en de lucht is _____ vandaag.",
        answers: ["zon", "blauw"],
      ),
      MultiplayerQuestion(
        question: "Ik _____ mijn huiswerk _____ ik naar bed ging.",
        answers: ["maakte", "voordat"],
      ),
      MultiplayerQuestion(
        question: "Ze legde het boek _____ de tafel en _____ de kamer.",
        answers: ["op", "verliet"],
      ),
      MultiplayerQuestion(
        question: "De _____ was erg _____, dus we besloten het te kopen.",
        answers: ["cake", "lekker"],
      ),
      MultiplayerQuestion(
        question: "Ze _____ in de tuin en _____ wat bloemen.",
        answers: ["werkten", "plantten"],
      ),
      MultiplayerQuestion(
        question:
            "Om een sandwich te maken, heb je _____, _____ en _____ nodig.",
        answers: ["brood", "boter", "kaas"],
      ),
      MultiplayerQuestion(
        question: "De kinderen _____ buiten omdat het _____ en zonnig was.",
        answers: ["speelden", "warm"],
      ),
      MultiplayerQuestion(
        question: "Ik kan mijn _____ niet vinden, kun je in de _____ kijken?",
        answers: ["telefoon", "keuken"],
      ),
      MultiplayerQuestion(
        question: "De _____ sprong over de _____ om het veld in te gaan.",
        answers: ["koe", "hek"],
      ),
      MultiplayerQuestion(
        question: "Als je _____ en _____ mengt, krijg je paars.",
        answers: ["rood", "blauw"],
      ),
      MultiplayerQuestion(
        question: "De kat achtervolgde de _____ door de _____.",
        answers: ["muis", "tuin"],
      ),
      MultiplayerQuestion(
        question: "We _____ gisteren een zandkasteel op het _____.",
        answers: ["maakten", "strand"],
      ),
      MultiplayerQuestion(
        question: "Het _____ opende het raam en liet de _____ binnen.",
        answers: ["kind", "lucht"],
      ),
      MultiplayerQuestion(
        question: "De _____ is te _____ om alleen op te tillen.",
        answers: ["doos", "zwaar"],
      ),
      MultiplayerQuestion(
        question: "Kun je me de _____, _____ en _____ voor de salade geven?",
        answers: ["tomaten", "komkommer", "sla"],
      ),
      MultiplayerQuestion(
        question: "Hij _____ de bal, maar het _____ over het hek.",
        answers: ["trapte", "vloog"],
      ),
      MultiplayerQuestion(
        question: "De sterren schijnen heel _____ in de _____ vanavond.",
        answers: ["helder", "lucht"],
      ),
      MultiplayerQuestion(
        question: "Schrijf alsjeblieft je _____ en _____ op het formulier.",
        answers: ["voornaam", "achternaam"],
      ),
      MultiplayerQuestion(
        question:
            "Ik _____ een nieuw boek over _____ en las het in één dag uit.",
        answers: ["las", "avontuur"],
      ),
      MultiplayerQuestion(
        question: "De _____ bakte brood terwijl de _____ soep maakte.",
        answers: ["bakker", "kok"],
      ),
      MultiplayerQuestion(
        question: "Het _____ viel van de tafel en brak.",
        answers: ["glas"],
      ),
      MultiplayerQuestion(
        question: "De _____ in het park zong prachtig deze ochtend.",
        answers: ["vogel"],
      ),
      MultiplayerQuestion(
        question: "De kamer was zo donker dat ik het _____ aan deed.",
        answers: ["licht"],
      ),
      MultiplayerQuestion(
        question: "Om een taart te bakken heb je bloem, eieren en _____ nodig.",
        answers: ["suiker"],
      ),
      MultiplayerQuestion(
        question: "De hond kwispelde met zijn _____ toen hij zijn baasje zag.",
        answers: ["staart"],
      ),
      MultiplayerQuestion(
        question: "De trein kwam vijf minuten te laat op het _____.",
        answers: ["station"],
      ),
      MultiplayerQuestion(
        question: "De leraar schreef de les op het _____.",
        answers: ["bord"],
      ),
      MultiplayerQuestion(
        question: "De baby hield het _____ stevig in haar handen vast.",
        answers: ["speelgoed"],
      ),
      MultiplayerQuestion(
        question: "De bloemen in de tuin roken naar _____.",
        answers: ["rozen"],
      ),
      MultiplayerQuestion(
        question: "De _____ blies alle bladeren van de bomen.",
        answers: ["wind"],
      ),
      MultiplayerQuestion(
        question: "De _____ stopte met werken omdat de batterijen leeg waren.",
        answers: ["klok"],
      ),
      MultiplayerQuestion(
        question: "De soep was te heet, dus ik wachtte tot het _____.",
        answers: ["afkoelde"],
      ),
      MultiplayerQuestion(
        question:
            "De kleine jongen verloor zijn _____ terwijl hij buiten speelde.",
        answers: ["hoed"],
      ),
      MultiplayerQuestion(
        question: "Ze opende de _____ om een glas water te pakken.",
        answers: ["koelkast"],
      ),
      MultiplayerQuestion(
        question: "De _____ zoemde rond de bloemen in de tuin.",
        answers: ["bij"],
      ),
      MultiplayerQuestion(
        question: "Ik moet een nieuwe _____ kopen omdat mijn oude kapot is.",
        answers: ["telefoon"],
      ),
      MultiplayerQuestion(
        question: "De _____ blafte luid om de vreemdeling weg te jagen.",
        answers: ["hond"],
      ),
      MultiplayerQuestion(
        question: "De _____ aan de hemel scheen de hele nacht.",
        answers: ["maan"],
      ),
      MultiplayerQuestion(
        question: "Het kind kleurde de tekening in met een rode _____.",
        answers: ["krijt"],
      ),
      MultiplayerQuestion(
        question: "De _____ droeg de appels in een houten mand.",
        answers: ["boer"],
      ),
    ],
    'german': [
      MultiplayerQuestion(
        question: "Ein _____ kann fliegen, aber ein Pinguin nicht.",
        answers: ["Vogel"],
      ),
      MultiplayerQuestion(
        question: "Der _____ bellte laut den Postboten an.",
        answers: ["Hund"],
      ),
      MultiplayerQuestion(
        question: "Ich _____ gestern ein Sandwich zum Mittagessen.",
        answers: ["aß"],
      ),
      MultiplayerQuestion(
        question: "Sie kaufte ein neues _____ für die Party.",
        answers: ["Kleid"],
      ),
      MultiplayerQuestion(
        question: "Um die Tür zu öffnen, brauchst du einen _____.",
        answers: ["Schlüssel"],
      ),
      MultiplayerQuestion(
        question: "Ich sah einen _____ am Himmel während des Gewitters.",
        answers: ["Blitz"],
      ),
      MultiplayerQuestion(
        question: "Bitte _____ das Fenster, bevor es anfängt zu regnen.",
        answers: ["schließe"],
      ),
      MultiplayerQuestion(
        question: "Das Baby spielt gerne mit einem bunten _____.",
        answers: ["Ball"],
      ),
      MultiplayerQuestion(
        question:
            "Sie _____ jedes Wochenende in den Park, um sich zu entspannen.",
        answers: ["gehen"],
      ),
      MultiplayerQuestion(
        question: "Die _____ war süß und saftig, wie der Sommer.",
        answers: ["Frucht"],
      ),
      MultiplayerQuestion(
        question: "Die _____ scheint und der Himmel ist _____ heute.",
        answers: ["Sonne", "blau"],
      ),
      MultiplayerQuestion(
        question: "Ich _____ meine Hausaufgaben _____ ich ins Bett ging.",
        answers: ["machte", "bevor"],
      ),
      MultiplayerQuestion(
        question: "Sie legte das Buch _____ den Tisch und _____ das Zimmer.",
        answers: ["auf", "verließ"],
      ),
      MultiplayerQuestion(
        question:
            "Der _____ war sehr _____, also entschieden wir uns, ihn zu kaufen.",
        answers: ["Kuchen", "lecker"],
      ),
      MultiplayerQuestion(
        question: "Sie _____ im Garten und _____ ein paar Blumen.",
        answers: ["arbeiteten", "pflanzten"],
      ),
      MultiplayerQuestion(
        question:
            "Um ein Sandwich zu machen, brauchst du _____, _____ und _____.",
        answers: ["Brot", "Butter", "Käse"],
      ),
      MultiplayerQuestion(
        question: "Die Kinder _____ draußen, weil es _____ und sonnig war.",
        answers: ["spielten", "warm"],
      ),
      MultiplayerQuestion(
        question:
            "Ich finde mein _____ nicht, kannst du in der _____ nachsehen?",
        answers: ["Telefon", "Küche"],
      ),
      MultiplayerQuestion(
        question: "Die _____ sprang über den _____, um auf das Feld zu kommen.",
        answers: ["Kuh", "Zaun"],
      ),
      MultiplayerQuestion(
        question: "Wenn du _____ und _____ mischst, bekommst du lila.",
        answers: ["rot", "blau"],
      ),
      MultiplayerQuestion(
        question: "Die Katze jagte die _____ über den _____.",
        answers: ["Maus", "Hof"],
      ),
      MultiplayerQuestion(
        question: "Wir _____ gestern eine Sandburg am _____.",
        answers: ["bauten", "Strand"],
      ),
      MultiplayerQuestion(
        question: "Das _____ öffnete das Fenster und ließ die _____ hinein.",
        answers: ["Kind", "Luft"],
      ),
      MultiplayerQuestion(
        question: "Die _____ ist zu _____, um sie alleine zu tragen.",
        answers: ["Kiste", "schwer"],
      ),
      MultiplayerQuestion(
        question:
            "Kannst du mir die _____, _____ und _____ für den Salat geben?",
        answers: ["Tomaten", "Gurke", "Salat"],
      ),
      MultiplayerQuestion(
        question: "Er _____ den Ball, aber er _____ über den Zaun.",
        answers: ["trat", "flog"],
      ),
      MultiplayerQuestion(
        question: "Die Sterne leuchten so _____ am _____ heute Nacht.",
        answers: ["hell", "Himmel"],
      ),
      MultiplayerQuestion(
        question: "Bitte schreibe deinen _____ und _____ auf das Formular.",
        answers: ["Vorname", "Nachname"],
      ),
      MultiplayerQuestion(
        question:
            "Ich _____ ein neues Buch über _____ und las es an einem Tag.",
        answers: ["las", "Abenteuer"],
      ),
      MultiplayerQuestion(
        question: "Der _____ backte Brot, während der _____ Suppe kochte.",
        answers: ["Bäcker", "Koch"],
      ),
      MultiplayerQuestion(
        question: "Das _____ fiel vom Tisch und zerbrach.",
        answers: ["Glas"],
      ),
      MultiplayerQuestion(
        question: "Der _____ im Park sang heute Morgen wunderschön.",
        answers: ["Vogel"],
      ),
      MultiplayerQuestion(
        question: "Der Raum war so dunkel, dass ich das _____ einschaltete.",
        answers: ["Licht"],
      ),
      MultiplayerQuestion(
        question: "Zum Backen eines Kuchens brauchst du Mehl, Eier und _____.",
        answers: ["Zucker"],
      ),
      MultiplayerQuestion(
        question:
            "Der Hund wedelte mit seinem _____, als er seinen Besitzer sah.",
        answers: ["Schwanz"],
      ),
      MultiplayerQuestion(
        question: "Der Zug kam fünf Minuten zu spät am _____ an.",
        answers: ["Bahnhof"],
      ),
      MultiplayerQuestion(
        question: "Der Lehrer schrieb die Lektion an die _____.",
        answers: ["Tafel"],
      ),
      MultiplayerQuestion(
        question: "Das Baby hielt das _____ fest in seinen Händen.",
        answers: ["Spielzeug"],
      ),
      MultiplayerQuestion(
        question: "Die Blumen im Garten rochen nach _____.",
        answers: ["Rosen"],
      ),
      MultiplayerQuestion(
        question: "Der _____ wehte alle Blätter von den Bäumen.",
        answers: ["Wind"],
      ),
      MultiplayerQuestion(
        question:
            "Die _____ hörte auf zu arbeiten, weil die Batterien leer waren.",
        answers: ["Uhr"],
      ),
      MultiplayerQuestion(
        question: "Die Suppe war zu heiß, also wartete ich, bis sie _____.",
        answers: ["abkühlte"],
      ),
      MultiplayerQuestion(
        question:
            "Der kleine Junge verlor seinen _____, während er draußen spielte.",
        answers: ["Hut"],
      ),
      MultiplayerQuestion(
        question: "Sie öffnete den _____, um ein Glas Wasser zu nehmen.",
        answers: ["Kühlschrank"],
      ),
      MultiplayerQuestion(
        question: "Die _____ summte um die Blumen im Garten herum.",
        answers: ["Biene"],
      ),
      MultiplayerQuestion(
        question:
            "Ich muss ein neues _____ kaufen, weil mein altes kaputt ist.",
        answers: ["Telefon"],
      ),
      MultiplayerQuestion(
        question: "Der _____ bellte laut, um den Fremden zu vertreiben.",
        answers: ["Hund"],
      ),
      MultiplayerQuestion(
        question: "Die _____ am Himmel schien die ganze Nacht.",
        answers: ["Mond"],
      ),
      MultiplayerQuestion(
        question: "Das Kind malte das Bild mit einem roten _____.",
        answers: ["Stift"],
      ),
      MultiplayerQuestion(
        question: "Der _____ trug die Äpfel in einem Holzkorb.",
        answers: ["Bauer"],
      ),
    ],
    'swiss': [
      MultiplayerQuestion(
        question: "E _____ cha flüge, aber e Pinguin nid.",
        answers: ["Vogel"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ hät laut de Briefträger averbellt.",
        answers: ["Hund"],
      ),
      MultiplayerQuestion(
        question: "Ich _____ geschter es Sandwich zum Zmittag.",
        answers: ["ha gässe"],
      ),
      MultiplayerQuestion(
        question: "Si hät es nöis _____ fürs Fäscht kauft.",
        answers: ["Chleid"],
      ),
      MultiplayerQuestion(
        question: "Um d’Türe z’öffne, bruuchsch en _____.",
        answers: ["Schlüssel"],
      ),
      MultiplayerQuestion(
        question: "Ich ha e _____ am Himmel gseh während em Gwitter.",
        answers: ["Blitz"],
      ),
      MultiplayerQuestion(
        question: "Bitte _____ s’Fänschter, bevor es afange regne.",
        answers: ["mach zue"],
      ),
      MultiplayerQuestion(
        question: "Dr Bueb spielt gärn mit ere farbige _____.",
        answers: ["Buebe"],
      ),
      MultiplayerQuestion(
        question: "Si _____ jede Wuche id Park zum Entspanne.",
        answers: ["gö"],
      ),
      MultiplayerQuestion(
        question: "D _____ isch süess und saftig gsi, grad wie de Summer.",
        answers: ["Frucht"],
      ),
      MultiplayerQuestion(
        question: "D _____ schynt und de Himmel isch _____ hüt.",
        answers: ["Sunne", "blau"],
      ),
      MultiplayerQuestion(
        question: "Ich _____ mini Ufgaabe _____, bevor ich is Bett gange bi.",
        answers: ["ha gmacht", "voher"],
      ),
      MultiplayerQuestion(
        question:
            "Si hät s’Buch _____ dr Tisch gleit und _____ s’Zimmer verloh.",
        answers: ["uf", "ha"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ isch so _____ gsi, drum hämmer e kauft.",
        answers: ["Kuche", "guet"],
      ),
      MultiplayerQuestion(
        question: "Si _____ im Garte und händ es paar Blueme _____.",
        answers: ["händ gschaffet", "pflanzt"],
      ),
      MultiplayerQuestion(
        question: "Für es Sandwich bruuchsch _____, _____ und _____.",
        answers: ["Brot", "Butter", "Chäs"],
      ),
      MultiplayerQuestion(
        question: "D Chind _____ dusse, will es _____ und sunnig gsi isch.",
        answers: ["händ gspilt", "warm"],
      ),
      MultiplayerQuestion(
        question: "Ich find mis _____ nid, chasch bitte i dr _____ go luege?",
        answers: ["Handy", "Chuchi"],
      ),
      MultiplayerQuestion(
        question: "D _____ isch über dr _____ gumpet, zum is Feld z’cho.",
        answers: ["Chue", "Hag"],
      ),
      MultiplayerQuestion(
        question: "Wenn du _____ und _____ mischisch, wirds violett.",
        answers: ["rot", "blau"],
      ),
      MultiplayerQuestion(
        question: "D Chatz hät dr _____ über dr _____ verjagt.",
        answers: ["Muis", "Hof"],
      ),
      MultiplayerQuestion(
        question: "Mir _____ geschter es Sandchaste am _____ gmacht.",
        answers: ["händ", "Strand"],
      ),
      MultiplayerQuestion(
        question: "Ds _____ hät s Fänschter ufgmacht und d’_____ isch inecho.",
        answers: ["Chind", "Luft"],
      ),
      MultiplayerQuestion(
        question: "D _____ isch z’_____ gsi, für dass me si allei trage cha.",
        answers: ["Kischte", "schwer"],
      ),
      MultiplayerQuestion(
        question: "Chasch mir d’_____, _____ und _____ für de Salat gä?",
        answers: ["Tomate", "Gurke", "Salat"],
      ),
      MultiplayerQuestion(
        question: "Er _____ dr Ball, aber er isch über dr Hag _____.",
        answers: ["hät gspickt", "gfloge"],
      ),
      MultiplayerQuestion(
        question: "D Stärne lüchted so _____ am _____ hüt am Abig.",
        answers: ["hell", "Himmel"],
      ),
      MultiplayerQuestion(
        question: "Bitte schriib dis _____ und dis _____ uf s’Formular.",
        answers: ["Vorname", "Name"],
      ),
      MultiplayerQuestion(
        question:
            "Ich _____ es nöis Buech über _____ gläse und s grad fertig gmacht.",
        answers: ["ha", "Abentüür"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ hät Brot bache, wärend dr _____ Suppe gmacht hät.",
        answers: ["Bäcker", "Choch"],
      ),
      MultiplayerQuestion(
        question: "Ds _____ isch vom Tisch gheit und zerbroche.",
        answers: ["Glas"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ im Park hät hüt Morge wunderschön gsunge.",
        answers: ["Vogel"],
      ),
      MultiplayerQuestion(
        question: "Dr Raum isch so dunkel gsi, drum ha ich s _____ agmacht.",
        answers: ["Licht"],
      ),
      MultiplayerQuestion(
        question: "Zum Chueche bache bruuchsch Mehl, Ei und _____.",
        answers: ["Zucker"],
      ),
      MultiplayerQuestion(
        question:
            "Dr Hund hät mit sim _____ gwedlet, wie er sim Bsitzer gseh hät.",
        answers: ["Schwanz"],
      ),
      MultiplayerQuestion(
        question: "Dr Zug isch fünf Minute z’spät am _____ cho.",
        answers: ["Bahnhof"],
      ),
      MultiplayerQuestion(
        question: "Dr Lehrer hät d Lektion uf d’_____ gschriebe.",
        answers: ["Tafel"],
      ),
      MultiplayerQuestion(
        question: "Ds Buebeli hät s _____ fescht i sine Händ gha.",
        answers: ["Spielsach"],
      ),
      MultiplayerQuestion(
        question: "D Blueme im Garte händ no _____ glüht.",
        answers: ["Rosen"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ hät alli Blätter vo de Bäum abe blosse.",
        answers: ["Wind"],
      ),
      MultiplayerQuestion(
        question:
            "D _____ hät ufghört z’arbeten, will d Batterien leer gsi sind.",
        answers: ["Uhr"],
      ),
      MultiplayerQuestion(
        question: "D Suppe isch z’heiss gsi, drum ha ich wartet, bis si _____.",
        answers: ["abgchillt"],
      ),
      MultiplayerQuestion(
        question:
            "Dr chlii Bueb hät sim _____ verlore, will er dussä gspilt hät.",
        answers: ["Huet"],
      ),
      MultiplayerQuestion(
        question: "Si hät dr _____ ufgmacht, um es Glas Wasser z’neh.",
        answers: ["Kühlschrank"],
      ),
      MultiplayerQuestion(
        question: "D _____ hät um d’Blueme im Garte ume gsummt.",
        answers: ["Bii"],
      ),
      MultiplayerQuestion(
        question: "Ich mues es nöis _____ chaufe, will mis Alts defekt isch.",
        answers: ["Handy"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ hät laut ghörrt, um dr Fremde z’verjage.",
        answers: ["Hund"],
      ),
      MultiplayerQuestion(
        question: "D _____ am Himmel hät d ganz Nacht glüht.",
        answers: ["Mond"],
      ),
      MultiplayerQuestion(
        question: "Ds Chind hät d Zeichnig mit ere _____ rot gmacht.",
        answers: ["Farbe"],
      ),
      MultiplayerQuestion(
        question: "Dr _____ hät d Äpfel in ere Holz-Chorb drage.",
        answers: ["Bauer"],
      ),
    ],
  };
}
