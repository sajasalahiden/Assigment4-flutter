import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color sky = Color(0xFF38BDF8); // sky blue
  static const Color skyDark = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: sky),
        appBarTheme: const AppBarTheme(
          backgroundColor: sky,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F9FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: skyDark, width: 2),
          ),
          labelStyle: const TextStyle(color: skyDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: skyDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const UsersPage(),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();

  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  bool _saving = false;

  Future<void> _saveUser() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();

    if (name.isEmpty) {
      _snack('Please enter name ');
      return;
    }
    if (name.length < 3) {
      _snack('Name must be at least 3 characters');
      return;
    }
    if (email.isEmpty) {
      _snack('Please enter email ');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _snack('Please enter a valid email');
      return;
    }

    setState(() => _saving = true);

    try {
      final newRef = _usersRef.push();
      await newRef.set({'name': name, 'email': email});

      _nameC.clear();
      _emailC.clear();
      _snack('Saved ');
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      await _usersRef.child(id).remove();
      _snack('Deleted ');
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Users')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                'Add a user (Name + Email) and it will be saved to Firebase Realtime Database.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameC,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveUser,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _usersRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No users yet'));
                  }

                  final raw =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final items = raw.entries.toList().reversed.toList();

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final entry = items[i];
                      final id = entry.key.toString();
                      final user = entry.value as Map<dynamic, dynamic>;

                      final name = (user['name'] ?? '').toString();
                      final email = (user['email'] ?? '').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 8,
                              offset: Offset(0, 2),
                              color: Color(0x11000000),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(email),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: const Color(0xFF0284C7),
                            onPressed: () => _deleteUser(id),
                            tooltip: 'Delete',
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
      ),
    );
  }
}
