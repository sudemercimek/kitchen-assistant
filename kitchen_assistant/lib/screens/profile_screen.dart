import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/recipe_card.dart';
import '../utils/ai_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final List<List<String>> shoppingLists = [[]];
  final List<List<bool>> shoppingChecked = [[]];
  final TextEditingController shoppingController = TextEditingController();
  bool showAIDrawer = false;
  bool showShoppingPanel = false;
  String aiResponse = '';
  int activeListIndex = 0;

  void _deleteRecipe(String docId) async {
    await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();
    final favRef = FirebaseFirestore.instance.collection('favorites').doc(user!.uid);
    final favDoc = await favRef.get();
    if (favDoc.exists) {
      List<String> favs = List<String>.from(favDoc['recipeIds'] ?? []);
      favs.remove(docId);
      await favRef.set({'recipeIds': favs}, SetOptions(merge: true));
    }
    setState(() {});
  }

  Future<List<QueryDocumentSnapshot>> _getUserRecipes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userId', isEqualTo: user?.uid)
        .get();
    return snapshot.docs;
  }

  void _toggleAIDrawer() {
    setState(() => showAIDrawer = !showAIDrawer);
  }

  void _toggleShoppingPanel() {
    setState(() => showShoppingPanel = !showShoppingPanel);
  }

  void _addShoppingItem() {
    final item = shoppingController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        shoppingLists[activeListIndex].add(item);
        shoppingChecked[activeListIndex].add(false);
      });
      shoppingController.clear();
    }
  }

  void _addNewList() {
    setState(() {
      shoppingLists.add([]);
      shoppingChecked.add([]);
      activeListIndex = shoppingLists.length - 1;
    });
  }

  void _deleteList(int index) {
    if (shoppingLists.length == 1) return;
    setState(() {
      shoppingLists.removeAt(index);
      shoppingChecked.removeAt(index);
      if (activeListIndex >= shoppingLists.length) activeListIndex = 0;
    });
  }

  void _askAI(String prompt) async {
    setState(() => aiResponse = '⏳ Loading...');
    try {
      final response = await AIService.ask(prompt);
      setState(() => aiResponse = response);
    } catch (e) {
      setState(() => aiResponse = 'Failed to get AI response: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8D8),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFEFE8D8),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (showShoppingPanel)
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Shopping Lists 🛒', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _addNewList,
                            tooltip: 'New List',
                          ),
                        ],
                      ),
                      if (shoppingLists.length > 1)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              shoppingLists.length,
                                  (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InputChip(
                                  label: Text('List ${i + 1}'),
                                  selected: i == activeListIndex,
                                  onSelected: (_) => setState(() => activeListIndex = i),
                                  onDeleted: () => _deleteList(i),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: shoppingController,
                        decoration: const InputDecoration(hintText: 'Add item'),
                        onSubmitted: (_) => _addShoppingItem(),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          itemCount: shoppingLists[activeListIndex].length,
                          itemBuilder: (context, i) => ListTile(
                            leading: Checkbox(
                              value: shoppingChecked[activeListIndex][i],
                              onChanged: (val) => setState(() => shoppingChecked[activeListIndex][i] = val ?? false),
                            ),
                            title: Text(shoppingLists[activeListIndex][i]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    final controller = TextEditingController(text: shoppingLists[activeListIndex][i]);
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Edit item'),
                                        content: TextField(controller: controller),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                shoppingLists[activeListIndex][i] = controller.text.trim();
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => setState(() {
                                    shoppingLists[activeListIndex].removeAt(i);
                                    shoppingChecked[activeListIndex].removeAt(i);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: FutureBuilder(
                  future: _getUserRecipes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!;
                    if (docs.isEmpty) {
                      return const Center(child: Text('You have not added any recipes yet.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final recipe = docs[index];
                        return Center(
                          child: SizedBox(
                            width: 420,
                            child: RecipeCard(
                              imageUrl: recipe['imageUrl'],
                              title: recipe['title'],
                              isFavorite: false,
                              onFavorite: null,
                              onDetail: () => Navigator.pushNamed(context, '/recipeDetail', arguments: recipe.id),
                              onDelete: () => _deleteRecipe(recipe.id),
                              showDeleteIcon: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (showAIDrawer)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 300,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Assistant 🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(
                      onSubmitted: _askAI,
                      decoration: const InputDecoration(hintText: 'What kind of recipe?'),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          aiResponse,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'shoppingBtn',
            onPressed: _toggleShoppingPanel,
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.list_alt),
          ),
          const Spacer(),
          FloatingActionButton(
            heroTag: 'aiBtn',
            onPressed: _toggleAIDrawer,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.smart_toy_outlined),
          ),
        ],
      ),
    );
  }
}
