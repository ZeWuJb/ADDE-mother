import 'package:adde/pages/name_suggestion/name_model.dart';
import 'package:adde/pages/name_suggestion/name_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NameSuggestionPage extends StatefulWidget {
  const NameSuggestionPage({super.key});

  @override
  _NameSuggestionPageState createState() => _NameSuggestionPageState();
}

class _NameSuggestionPageState extends State<NameSuggestionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Provider.of<NameProvider>(context, listen: false).fetchNames();
      setState(() {
        _isLoading = false;
        print('Initialized NameSuggestionPage');
      });
    } catch (e) {
      print('Error initializing NameSuggestionPage: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameProvider = Provider.of<NameProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Baby Name Suggester'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.pink,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Christian'),
            Tab(text: 'Muslim'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildNameList(nameProvider.names, null),
                  _buildNameList(
                    nameProvider.names
                        .where((name) => name.religion == 'Christian')
                        .toList(),
                    'Christian',
                  ),
                  _buildNameList(
                    nameProvider.names
                        .where((name) => name.religion == 'Muslim')
                        .toList(),
                    'Muslim',
                  ),
                ],
              ),
    );
  }

  Widget _buildNameList(List<Name> names, String? religion) {
    final boys = names.where((name) => name.gender == 'Boy').toList();
    final girls = names.where((name) => name.gender == 'Girl').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (boys.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Boys',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...boys.map((name) => _buildNameTile(name)),
        ],
        if (girls.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Girls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...girls.map((name) => _buildNameTile(name)),
        ],
        if (boys.isEmpty && girls.isEmpty)
          Center(
            child: Text(
              'No names available for ${religion ?? 'this category'}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildNameTile(Name name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            name.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            name.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            name.gender == 'Boy' ? Icons.male : Icons.female,
            color: name.gender == 'Boy' ? Colors.blue : Colors.pink,
          ),
        ),
      ),
    );
  }
}
