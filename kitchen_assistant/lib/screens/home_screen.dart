import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/recipe_card.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> favoriteRecipeIds = {};

  @override
  void initState() {
    super.initState();
    fetchUserFavorites();
  }

  Future<void> fetchUserFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('favorites').doc(user.uid).get();
    final favorites = List<String>.from(doc.data()?['recipeIds'] ?? []);

    setState(() {
      favoriteRecipeIds = favorites.toSet();
    });
  }

  Future<void> toggleFavorite(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('favorites').doc(user.uid);
    final snapshot = await ref.get();
    final currentFavorites = List<String>.from(snapshot.data()?['recipeIds'] ?? []);

    if (currentFavorites.contains(recipeId)) {
      currentFavorites.remove(recipeId);
    } else {
      currentFavorites.add(recipeId);
    }

    await ref.set({'recipeIds': currentFavorites}, SetOptions(merge: true));
    fetchUserFavorites();
  }

  void _onDetailPressed(String recipeId) async {
    final result = await Navigator.pushNamed(context, '/recipeDetail', arguments: recipeId);
    if (result == true) {
      await fetchUserFavorites();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.pushNamed(context, '/addRecipe');
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchFilteredRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    final recipes = snapshot.docs;
    if (_searchQuery.isEmpty) return recipes;

    return recipes.where((doc) {
      final title = doc['title'].toString().toLowerCase();
      return title.contains(_searchQuery);
    }).toList();
  }

  Widget _buildRecipeList(bool showFavoritesOnly) {
    return FutureBuilder(
      future: _fetchFilteredRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No matching recipes found.'));
        }

        final allRecipes = snapshot.data!;
        final recipeDocs = showFavoritesOnly
            ? allRecipes.where((doc) => favoriteRecipeIds.contains(doc.id)).toList()
            : allRecipes;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: recipeDocs.length,
          itemBuilder: (context, index) {
            final recipe = recipeDocs[index];
            return Center(
              child: SizedBox(
                width: 420,
                child: RecipeCard(
                  imageUrl: recipe['imageUrl'],
                  title: recipe['title'],
                  isFavorite: favoriteRecipeIds.contains(recipe.id),
                  onFavorite: () => toggleFavorite(recipe.id),
                  onDetail: () => _onDetailPressed(recipe.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  late final List<Widget> _pages = [
    _buildRecipeList(false),
    _buildRecipeList(true),
    const SizedBox(),
    const ProfileScreen(),
  ];
// sayfa tasarımı
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E0D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5E0D8),
        elevation: 0,
        automaticallyImplyLeading: _selectedIndex != 0,
        leading: _selectedIndex != 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => setState(() => _selectedIndex = 0),
        )
            : null,
        title: Row(
          children: [
            SizedBox(
              width: 180,
              height: 40,
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) {
                  setState(() {
                    _searchQuery = _searchController.text.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = _searchController.text.trim().toLowerCase();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Search'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildRecipeList(false)
          : _selectedIndex == 1
          ? _buildRecipeList(true)
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF725C3F),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFEFE8D8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
