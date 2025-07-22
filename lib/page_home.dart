import 'package:flutter/material.dart';
import 'package:bakinglog/page_recipe.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/main.dart';
import 'page_settings.dart';

typedef RecipeClicked = Function(Recipe recipe);

class RecipeListItem extends StatelessWidget {
  RecipeListItem(
      {required this.recipe,
      required this.refreshCallback,
      required this.deleteCallback,
      required this.toggleFavoriteCallback})
      : super(key: ObjectKey(recipe));

  final Recipe recipe;
  final Function() refreshCallback;
  final Function(Object) deleteCallback;
  final Function(Recipe) toggleFavoriteCallback;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RecipePage(recipe: recipe)))
            .then((_) => refreshCallback());
      },
      title: Text(recipe.recipeName),
      subtitle: Text(recipe.dateCreated.toString(),
          style: const TextStyle(fontWeight: FontWeight.w200)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: recipe.isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              toggleFavoriteCallback(recipe);
            },
          ),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog(context);
              }),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              }, // 대화 상자 닫기
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteCallback(recipe); // 삭제 작업 수행
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class RecipeList extends StatefulWidget {
  const RecipeList({required this.userData, required this.lastSyncStatus, required this.lastSyncTime, required this.onSave, required this.onSyncFromCloud, super.key});

  final UserData userData;
  final String? lastSyncStatus;
  final DateTime? lastSyncTime;
  final Future<void> Function() onSave;
  final VoidCallback onSyncFromCloud;

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  bool _isSearching = false;
  String _searchQuery = '';
  List<Recipe> _filteredRecipes = [];

  List<Recipe> get recipes => widget.userData.recipes;
  String get appVersion => widget.userData.appVersion;

  void refresh() {
    setState(() {});
  }

  void deleteRecipe(Object obj) {
    setState(() {
      recipes.remove(obj);
      _filterRecipes();
    });
    widget.onSave();
  }

  void toggleFavorite(Recipe recipe) {
    setState(() {
      recipe.isFavorite = !recipe.isFavorite;
      _filterRecipes();
    });
    widget.onSave();
  }

  void _filterRecipes() {
    if (_searchQuery.isEmpty) {
      _filteredRecipes = List.from(recipes);
    } else {
      _filteredRecipes = recipes
          .where((recipe) => recipe.recipeName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Favorite 레시피들을 상단에 정렬
    _filteredRecipes.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return 0;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _filteredRecipes = List.from(recipes);
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _filteredRecipes = List.from(recipes);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterRecipes();
    });
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          userData: widget.userData,
          onUserDataChanged: (newData) {
            setState(() {
              widget.userData.recipes = newData.recipes;
              widget.userData.appVersion = newData.appVersion;
            });
          },
          lastSyncStatus: widget.lastSyncStatus,
          lastSyncTime: widget.lastSyncTime,
          onSyncFromCloud: widget.onSyncFromCloud,
        ),
      ),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _filteredRecipes = List.from(recipes);
  }

  @override
  void didUpdateWidget(RecipeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filterRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search recipes...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchChanged,
                )
              : Text(
                  'BakeLog v$appVersion',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            if (!_isSearching) ...[
              IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'New Recipe',
                  onPressed: () {
                    setState(() {
                      recipes.add(Recipe.createNew(
                          'new', DateTime.now().toString().substring(0, 16)));
                    });
                    widget.onSave();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RecipePage(
                                recipe: recipes.last,
                                isEdit: true))).then((_) => refresh());
                  }),
              IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _startSearch),
              IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _openSettings),
            ] else ...[
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _stopSearch),
            ],
          ]),
      body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: _filteredRecipes.map((recipe) {
            return RecipeListItem(
              recipe: recipe,
              refreshCallback: refresh,
              deleteCallback: deleteRecipe,
              toggleFavoriteCallback: toggleFavorite,
            );
          }).toList()),
    );
  }
}
