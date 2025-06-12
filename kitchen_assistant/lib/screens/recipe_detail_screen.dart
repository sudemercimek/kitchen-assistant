import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late String recipeId;
  final TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  bool isFavorite = false;
  int likes = 0;
  late TabController _tabController;
  User? currentUser;
  bool favoriteChanged = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    recipeId = ModalRoute.of(context)!.settings.arguments as String;
    fetchLikeStatus();
    checkFavoriteStatus();
  }

  Future<void> fetchLikeStatus() async {
    final user = currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('recipeLikes').doc(recipeId).get();
    final likedUsers = List<String>.from(doc.data()?['users'] ?? []);
    setState(() {
      isLiked = likedUsers.contains(user.uid);
      likes = likedUsers.length;
    });
  }

  Future<void> checkFavoriteStatus() async {
    final user = currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('favorites').doc(user.uid).get();
    final favorites = List<String>.from(doc.data()?['recipeIds'] ?? []);
    setState(() {
      isFavorite = favorites.contains(recipeId);
    });
  }

  Future<void> toggleLike() async {
    final user = currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('recipeLikes').doc(recipeId);
    final doc = await ref.get();
    final users = List<String>.from(doc.data()?['users'] ?? []);
    if (isLiked) {
      users.remove(user.uid);
    } else {
      users.add(user.uid);
    }
    await ref.set({'users': users});
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({'likes': users.length});
    fetchLikeStatus();
  }

  Future<void> toggleFavorite() async {
    final user = currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('favorites').doc(user.uid);
    final doc = await ref.get();
    final recipeIds = List<String>.from(doc.data()?['recipeIds'] ?? []);
    if (isFavorite) {
      recipeIds.remove(recipeId);
    } else {
      recipeIds.add(recipeId);
    }
    await ref.set({'recipeIds': recipeIds}, SetOptions(merge: true));
    favoriteChanged = true;
    await checkFavoriteStatus();
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty || currentUser == null) return;
    final comment = {'email': currentUser!.email, 'text': text.trim()};
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({
      'comments': FieldValue.arrayUnion([comment])
    });
    _commentController.clear();
  }

  Future<void> deleteComment(Map<String, dynamic> comment) async {
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({
      'comments': FieldValue.arrayRemove([comment])
    });
  }

  Widget buildImage(String imageUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 160,
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (favoriteChanged) {
      Navigator.pop(context, true);
    }
    super.dispose();
  }

  @override //tarif
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').doc(recipeId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'No Title';
        final description = data['description'] ?? '';
        final imageUrl = data['imageUrl'] ?? '';
        final ingredients = List<String>.from(data['ingredients'] ?? []);
        final steps = List<String>.from(data['steps'] ?? []);
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        likes = data['likes'] ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFFEFE8D8),
          appBar: AppBar(
            backgroundColor: const Color(0xFFEFE8D8),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Text(title, style: const TextStyle(color: Colors.black87)),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.teal,
              tabs: const [
                Tab(text: 'View'),
                Tab(text: 'Ingredients'),
                Tab(text: 'Steps'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // VIEW
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  buildImage(imageUrl),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.pink,
                        ),
                        onPressed: toggleLike,
                      ),
                      Text('$likes likes'),
                    ],
                  ),
                  const Divider(),
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...comments.map((c) {
                    final isOwner = c['email'] == currentUser?.email;
                    return Card(
                      color: const Color(0xFFF7F5FF),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.comment, color: Colors.teal),
                        title: Text("${c['email']}: ${c['text']}"),
                        trailing: isOwner
                            ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => deleteComment(c),
                        )
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => addComment(_commentController.text),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              // INGREDIENTS
              ListView(
                children: [
                  buildImage(imageUrl),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...ingredients.map((item) => ListTile(title: Text(item))),
                ],
              ),
              // STEPS
              ListView(
                children: [
                  buildImage(imageUrl),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...steps.asMap().entries.map((e) => ListTile(
                    leading: CircleAvatar(radius: 12, child: Text('${e.key + 1}')),
                    title: Text(e.value),
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
