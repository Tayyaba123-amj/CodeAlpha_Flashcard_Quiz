
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashcardApp());
}

// ================= APP =================

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flashcard Quiz',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF7F4FF),
      ),
      home: const FlashcardHome(),
    );
  }
}

// ================= FLASHCARD MODEL =================

class Flashcard {
  String question;
  String answer;
  bool isFavourite;

  Flashcard({
    required this.question,
    required this.answer,
    this.isFavourite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'isFavourite': isFavourite,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      isFavourite: map['isFavourite'] ?? false,
    );
  }
}

// ================= HOME SCREEN =================

class FlashcardHome extends StatefulWidget {
  const FlashcardHome({super.key});

  @override
  State<FlashcardHome> createState() => _FlashcardHomeState();
}

class _FlashcardHomeState extends State<FlashcardHome> {
  final TextEditingController searchController = TextEditingController();

  final List<Flashcard> cards = [];

  int currentIndex = 0;
  int bestScore = 0;

  bool isLoading = true;
  bool showAnswer = false;
  bool favouritesOnly = false;

  // Quiz variables
  List<Flashcard> quizCards = [];
  List<String> quizOptions = [];

  int quizIndex = 0;
  int quizScore = 0;

  String? selectedOption;
  bool quizFinished = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ================= DEFAULT CARDS =================

  List<Flashcard> defaultCards() {
    return [
      Flashcard(
        question: 'What is Flutter?',
        answer: 'Flutter is Google’s UI toolkit for building applications.',
      ),
      Flashcard(
        question: 'Which programming language does Flutter use?',
        answer: 'Flutter uses the Dart programming language.',
      ),
      Flashcard(
        question: 'What is a Widget?',
        answer: 'A widget is the basic building block of Flutter UI.',
      ),
      Flashcard(
        question: 'What is Dart?',
        answer: 'Dart is an object-oriented programming language developed by Google.',
      ),
      Flashcard(
        question: 'What is OOP?',
        answer: 'OOP stands for Object-Oriented Programming.',
      ),
      Flashcard(
        question: 'What is a Class?',
        answer: 'A class is a blueprint used to create objects.',
      ),
      Flashcard(
        question: 'What is an Object?',
        answer: 'An object is an instance of a class.',
      ),
      Flashcard(
        question: 'What is Firebase?',
        answer: 'Firebase is a platform by Google that provides backend services.',
      ),
      Flashcard(
        question: 'What is a Database?',
        answer: 'A database stores and organizes information.',
      ),
      Flashcard(
        question: 'What is an API?',
        answer: 'API stands for Application Programming Interface.',
      ),
    ];
  }

  // ================= LOAD DATA =================

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCards = prefs.getString('flashcards');

      if (!mounted) return;

      setState(() {
        bestScore = prefs.getInt('bestScore') ?? 0;

        if (savedCards != null) {
          final decoded = jsonDecode(savedCards) as List;

          cards.addAll(
            decoded.map(
              (item) => Flashcard.fromMap(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
        } else {
          cards.addAll(defaultCards());
        }

        isLoading = false;
      });

      if (savedCards == null) {
        await saveData();
      }
    } catch (e) {
      debugPrint('Load error: $e');

      if (!mounted) return;

      setState(() {
        if (cards.isEmpty) {
          cards.addAll(defaultCards());
        }
        isLoading = false;
      });
    }
  }

  // ================= SAVE DATA =================

  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'flashcards',
        jsonEncode(cards.map((card) => card.toMap()).toList()),
      );

      await prefs.setInt('bestScore', bestScore);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  // ================= FILTER CARDS =================

  List<Flashcard> get visibleCards {
    List<Flashcard> result = List.from(cards);

    if (favouritesOnly) {
      result = result.where((card) => card.isFavourite).toList();
    }

    final query = searchController.text.toLowerCase().trim();

    if (query.isNotEmpty) {
      result = result.where((card) {
        return card.question.toLowerCase().contains(query) ||
            card.answer.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  // ================= ADD / EDIT CARD =================

  Future<void> openCardDialog({int? index}) async {
    final questionController = TextEditingController(
      text: index == null ? '' : cards[index].question,
    );

    final answerController = TextEditingController(
      text: index == null ? '' : cards[index].answer,
    );

    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              index == null ? 'Add Flashcard' : 'Edit Flashcard',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a question';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: answerController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Answer',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an answer';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (result == true && mounted) {
        setState(() {
          if (index == null) {
            cards.add(
              Flashcard(
                question: questionController.text.trim(),
                answer: answerController.text.trim(),
              ),
            );
          } else {
            cards[index].question = questionController.text.trim();
            cards[index].answer = answerController.text.trim();
          }

          currentIndex = 0;
          showAnswer = false;
        });

        await saveData();
      }
    } finally {
      questionController.dispose();
      answerController.dispose();
    }
  }

  // ================= DELETE CARD =================

  Future<void> deleteCard(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Flashcard?'),
          content: const Text(
            'Are you sure you want to delete this card?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() {
        cards.removeAt(index);
        currentIndex = 0;
        showAnswer = false;
      });

      await saveData();
    }
  }

  // ================= FAVOURITE =================

  Future<void> toggleFavourite(Flashcard card) async {
    setState(() {
      card.isFavourite = !card.isFavourite;
    });

    await saveData();
  }

  // ================= NEXT CARD =================

  void nextCard() {
    final list = visibleCards;

    if (list.isEmpty) return;

    setState(() {
      currentIndex = (currentIndex + 1) % list.length;
      showAnswer = false;
    });
  }

  // ================= PREVIOUS CARD =================

  void previousCard() {
    final list = visibleCards;

    if (list.isEmpty) return;

    setState(() {
      currentIndex = (currentIndex - 1 + list.length) % list.length;
      showAnswer = false;
    });
  }

  // ================= SHUFFLE =================

  void shuffleCards() {
    final list = visibleCards;

    if (list.isEmpty) return;

    setState(() {
      final randomCard = list[Random().nextInt(list.length)];
      currentIndex = list.indexOf(randomCard);
      showAnswer = false;
    });
  }

  // =================================================
  //                    QUIZ FUNCTIONS
  // =================================================

  // START QUIZ

  void startQuiz() {
    if (cards.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least 2 flashcards to start the quiz.',
          ),
        ),
      );
      return;
    }

    // Make a separate copy for the quiz.
    final questionList = cards
        .map(
          (card) => Flashcard(
            question: card.question,
            answer: card.answer,
          ),
        )
        .toList();

    questionList.shuffle();

    setState(() {
      quizCards = questionList;
      quizIndex = 0;
      quizScore = 0;
      selectedOption = null;
      quizFinished = false;

      createQuizOptions();
    });
  }

  // CREATE MCQ OPTIONS

  void createQuizOptions() {
    final correctAnswer = quizCards[quizIndex].answer;

    final otherAnswers = quizCards
        .map((card) => card.answer)
        .where((answer) => answer != correctAnswer)
        .toSet()
        .toList();

    otherAnswers.shuffle();

    // One correct answer + up to three wrong answers.
    quizOptions = [
      correctAnswer,
      ...otherAnswers.take(3),
    ];

    quizOptions.shuffle();
  }

  // SELECT ANSWER

  void chooseQuizAnswer(String answer) {
    if (selectedOption != null || quizFinished) return;

    setState(() {
      selectedOption = answer;

      if (answer == quizCards[quizIndex].answer) {
        quizScore++;
      }
    });
  }

  // NEXT QUESTION

  Future<void> nextQuizQuestion() async {
    if (selectedOption == null) return;

    if (quizIndex < quizCards.length - 1) {
      setState(() {
        quizIndex++;
        selectedOption = null;
        createQuizOptions();
      });
    } else {
      await finishQuiz();
    }
  }

  // FINISH QUIZ

  Future<void> finishQuiz() async {
    setState(() {
      quizFinished = true;

      if (quizScore > bestScore) {
        bestScore = quizScore;
      }
    });

    await saveData();
  }

  // EXIT QUIZ

  void exitQuiz() {
    setState(() {
      quizCards = [];
      quizOptions = [];
      quizIndex = 0;
      quizScore = 0;
      selectedOption = null;
      quizFinished = false;
    });
  }

  // =================================================
  //                    MAIN SCREEN
  // =================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show quiz whenever quiz is active.
    if (quizCards.isNotEmpty) {
      return buildQuizScreen();
    }

    final list = visibleCards;

    if (currentIndex >= list.length) {
      currentIndex = 0;
    }

    final Flashcard? currentCard =
        list.isEmpty ? null : list[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flashcard Quiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Best Score',
            onPressed: () async {
              setState(() {
                bestScore = 0;
              });
              await saveData();
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCardDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // WELCOME CARD

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7652D5),
                        Color(0xFFAA83F5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Learner! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Learn something new every day.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // STATISTICS

                Row(
                  children: [
                    Expanded(
                      child: statCard(
                        'Total Cards',
                        '${cards.length}',
                        Icons.style,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard(
                        'Favourites',
                        '${cards.where((c) => c.isFavourite).length}',
                        Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard(
                        'Best Score',
                        '$bestScore',
                        Icons.emoji_events,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SEARCH

                TextField(
                  controller: searchController,
                  onChanged: (_) {
                    setState(() {
                      currentIndex = 0;
                      showAnswer = false;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search questions or answers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                currentIndex = 0;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // FILTERS

                Wrap(
                  spacing: 10,
                  children: [
                    FilterChip(
                      label: const Text('All Cards'),
                      selected: !favouritesOnly,
                      onSelected: (_) {
                        setState(() {
                          favouritesOnly = false;
                          currentIndex = 0;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Favourites ❤️'),
                      selected: favouritesOnly,
                      onSelected: (_) {
                        setState(() {
                          favouritesOnly = true;
                          currentIndex = 0;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Your Flashcards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // FLASHCARD DISPLAY

                if (currentCard == null)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 55,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No flashcards found!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Add a card or change your search/filter.',
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6842C2),
                          Color(0xFF9670E8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FLASHCARD',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    toggleFavourite(currentCard);
                                  },
                                  icon: Icon(
                                    currentCard.isFavourite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.white,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    final index =
                                        cards.indexOf(currentCard);

                                    if (value == 'edit') {
                                      openCardDialog(index: index);
                                    } else if (value == 'delete') {
                                      deleteCard(index);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          currentCard.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 22),

                        if (showAnswer)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentCard.answer,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),

                        const SizedBox(height: 15),

                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              showAnswer = !showAnswer;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          icon: Icon(
                            showAnswer
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          label: Text(
                            showAnswer ? 'Hide Answer' : 'Show Answer',
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Card ${currentIndex + 1} of ${list.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),

                // PREVIOUS AND NEXT

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: list.isEmpty ? null : previousCard,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: list.isEmpty ? null : nextCard,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),

                // SHUFFLE

                OutlinedButton.icon(
                  onPressed: list.isEmpty ? null : shuffleCards,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle Cards'),
                ),

                const SizedBox(height: 12),

                // START QUIZ

                ElevatedButton.icon(
                  onPressed: startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(17),
                  ),
                  icon: const Icon(Icons.quiz),
                  label: const Text(
                    'Start Quiz',
                    style: TextStyle(fontSize: 17),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= STATISTICS CARD =================

  Widget statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =================================================
  //                    QUIZ SCREEN
  // =================================================

  Widget buildQuizScreen() {
    // ================= RESULT SCREEN =================

    if (quizFinished) {
      final percentage =
          ((quizScore / quizCards.length) * 100).round();

      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Result'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.orange,
                    size: 90,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quiz Completed!',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '$quizScore / ${quizCards.length}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Percentage: $percentage%',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Best Score: $bestScore',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: startQuiz,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: exitQuiz,
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ================= CURRENT QUESTION =================

    final currentCard = quizCards[quizIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: exitQuiz,
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),

            // SingleChildScrollView fixes bottom overflow.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PROGRESS BAR

                  LinearProgressIndicator(
                    value: (quizIndex + 1) / quizCards.length,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.deepPurple,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Question ${quizIndex + 1} of ${quizCards.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 25),

                  // QUESTION

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentCard.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Choose the correct answer:',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // MCQ OPTIONS

                  ...quizOptions.map((option) {
                    final isCorrect =
                        option == currentCard.answer;

                    final isSelected =
                        option == selectedOption;

                    Color backgroundColor = Colors.white;
                    Color borderColor = Colors.deepPurple;

                    if (selectedOption != null && isCorrect) {
                      backgroundColor = Colors.green.shade100;
                      borderColor = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      backgroundColor = Colors.red.shade100;
                      borderColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        onTap: selectedOption == null
                            ? () => chooseQuizAnswer(option)
                            : null,
                        title: Text(option),
                        trailing: selectedOption == null
                            ? const Icon(Icons.circle_outlined)
                            : isCorrect
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : isSelected
                                    ? const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      )
                                    : null,
                      ),
                    );
                  }),

                  // ANSWER FEEDBACK

                  if (selectedOption != null) ...[
                    const SizedBox(height: 8),

                    Text(
                      selectedOption == currentCard.answer
                          ? 'Correct Answer! 🎉'
                          : 'Wrong Answer! The correct answer is:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: selectedOption == currentCard.answer
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),

                    if (selectedOption != currentCard.answer)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          currentCard.answer,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],

                  const SizedBox(height: 20),

                  // SCORE

                  Text(
                    'Your Score: $quizScore',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // NEXT QUESTION / FINISH BUTTON

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedOption == null
                          ? null
                          : nextQuizQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        quizIndex == quizCards.length - 1
                            ? 'Finish Quiz'
                            : 'Next Question',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
