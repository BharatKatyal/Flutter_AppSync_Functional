
import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_aws_appsync/models/ModelProvider.dart';

import 'amplifyconfiguration.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    final api = AmplifyAPI(modelProvider: ModelProvider.instance);
    await Amplify.addPlugin(api);

    try {
      await Amplify.configure(amplifyconfig);
    } on AmplifyAlreadyConfiguredException {
      safePrint(
          'Tried to reconfigure Amplify; this can occur when your app restarts on Android.');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Todo?> _todos = []; // Add a list to store the fetched todos

  @override
  initState() {
    super.initState();
    _fetchTodos(); // Call the method to fetch todos on app start
  }

  int _counter = 0;
  void _fetchTodos() async {
    final todos = await queryListItems();
    setState(() {
      _todos = todos;
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // AWS Methods
  Future<void> createTodo() async {
    try {
      final todo = Todo(name: 'my first todo', description: 'todo description');
      final request = ModelMutations.create(todo);
      final response = await Amplify.API.mutate(request: request).response;

      final createdTodo = response.data;
      if (createdTodo == null) {
        safePrint('errors: ${response.errors}');
        return;
      }
      safePrint('Mutation result: ${createdTodo.name}');
    } on ApiException catch (e) {
      safePrint('Mutation failed: $e');
    }
  }

  // query one item
  Future<Todo?> queryItem(Todo queriedTodo) async {
    try {
      final request = ModelQueries.get(Todo.classType, queriedTodo.id);
      final response = await Amplify.API.query(request: request).response;
      final todo = response.data;
      if (todo == null) {
        safePrint('errors: ${response.errors}');
      }
      return todo;
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
      return null;
    }
  }

  // fetch all
  Future<List<Todo?>> queryListItems() async {
    try {
      final request = ModelQueries.list(Todo.classType);
      final response = await Amplify.API.query(request: request).response;

      final todos = response.data?.items;
      if (todos == null) {
        safePrint('errors: ${response.errors}');
        return <Todo?>[];
      }
      return todos;
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
    }
    return <Todo?>[];
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(
              child: const Text("Create a table in AWS"),
              key: const Key('createOneItemAws'),
              onPressed: createTodo,
            ),
            OutlinedButton(
              child: const Text("List all Elements in AWS"),
              key: const Key('fetchAllElementsAws'),
              onPressed: _fetchTodos, // Call the new method to fetch todos
            ),
            // Add a ListView to display the fetched todos
            Expanded(
              child: ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return ListTile(
                    title: Text(todo?.name ?? 'No name'),
                    subtitle: Text(todo?.description ?? 'No description'),
                  );
                },
              ),
            ),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
