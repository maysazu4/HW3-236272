import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:hello_me/auth_repository.dart';
import 'package:hello_me/Login.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';
import 'dart:io';


void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthRepository>(
      create: (_) => AuthRepository.instance(),
      child: Consumer<AuthRepository>(
        builder: (context, _login, _) =>
            MaterialApp(
              title: 'Startup Name Generator',
              theme: ThemeData(
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  )
              ),
              initialRoute: '/',
              routes: {
                '/': (context) => RandomWords(),
                '/login': (context) => LoginScreen(),
              },
            ),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key});


  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  late AuthRepository firebaseUser;
  final ScrollController listController = ScrollController();
  final sheetController = SnappingSheetController();
  bool sheetOn = false;
  @override
  Widget build(BuildContext context) {
    firebaseUser = Provider.of<AuthRepository>(context,listen: false);
    var icon = Icons.login;
    var onPressedFunc = _loginScreen;
    if( firebaseUser.isAuthenticated){
      icon = Icons.exit_to_app;
      onPressedFunc = _pushLogout;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
            icon: Icon(icon),
            onPressed: onPressedFunc,
            tooltip: 'Login Page',
          ),
        ],
      ),
      body: firebaseUser.isAuthenticated ? GestureDetector(
        child: SnappingSheet(
          controller: sheetController ,
          lockOverflowDrag: true,
          snappingPositions: getSnappingPositions(),
          grabbing: _getGrabbing(changeState),
          grabbingHeight: 45,
          sheetAbove: sheetOn ?
          SnappingSheetContent(child:  ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 2.5,
                sigmaY: 2.5,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
              draggable: false
          ) : null,
          sheetBelow:  SnappingSheetContent(child:UserSnappingSheet(),
              draggable: true) ,
          child: _buildSuggestions(),

        )
      ) :
      _buildSuggestions()
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int i) {
          if (i.isOdd) {
            return const Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          final alreadySaved = _saved.contains(_suggestions[index]);
          final alreadySavedInUserData = (firebaseUser.isAuthenticated)
              && (firebaseUser.getData().contains(_suggestions[index]));
          final isSaved = alreadySaved || alreadySavedInUserData;
          if (alreadySaved && !alreadySavedInUserData) {
            if (firebaseUser.user != null) {
              firebaseUser.updateSavedSuggestions(
                  _suggestions[index], _suggestions[index].first,
                  _suggestions[index].second);
            }
          }
          return ListTile(
            title: Text(
              _suggestions[index].asPascalCase,
              style: _biggerFont,
            ),
            trailing: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Colors.red : null,
              semanticLabel: isSaved ? 'Remove from saved' : 'Save',
            ),
            onTap: () {
              setState(() {
                if (isSaved) {
                  setState(() {
                    _saved.remove(_suggestions[index]);
                  });
                  if (firebaseUser.user != null) {
                    if (firebaseUser.getData().contains(_suggestions[index])) {
                      if (isSaved) {
                        firebaseUser.getData().remove(_suggestions[index]);
                      }
                    }
                    firebaseUser.updateSavedSuggestions(
                        _suggestions[index], '', '',
                        remove: _suggestions[index]);
                  }
                } else {
                  _saved.add(_suggestions[index]);
                  if (firebaseUser.isAuthenticated) {
                    firebaseUser.updateSavedSuggestions(
                        _suggestions[index], _suggestions[index].first,
                        _suggestions[index].second);
                  }
                }
              });
            },
          );
        }
    );
  }



  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          firebaseUser =Provider.of<AuthRepository>(context);
          var savedSug = _saved;
          if(firebaseUser.isAuthenticated){
            savedSug = _saved.union(firebaseUser.getData());
          }
          final tiles = savedSug.map(
                (pair) {
              return Dismissible(
                key: ValueKey<WordPair>(pair),
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    if(firebaseUser.getData().contains(pair)){
                      firebaseUser.getData().remove(pair);
                    }
                    setState(() {
                      _saved.remove(pair);
                    });
                    if(firebaseUser.user != null) {
                      firebaseUser.updateSavedSuggestions(pair,'' , '',remove:pair);
                    }

                  });
                 },
                confirmDismiss: (DismissDirection direction) async {
                  String string = pair.asPascalCase;
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Delete Confirmation"),
                        content: Text("Are you sure you want to delete "
                            " $string from your saved suggestions?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Yes")
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("No"),
                          ),
                        ],
                      );
                    },
                  );
                },
                background: Container(
                  color: Colors.deepPurple,
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Delete Suggestion',
                        style: TextStyle(color: Colors.white, fontSize: 18.0),),
                      // Text(data)
                    ],

                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.deepPurple,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      Text('Delete Suggestion',
                        style: TextStyle(color: Colors.white, fontSize: 18.0),),
                      // Text(data)
                    ],
                  ),
                ),

                child:
                ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }



  void _pushLogout() async{
    const signoutSnackBar = SnackBar(
        content: Text('Successfully logged out'));
    _saved.clear();
    await firebaseUser.signOut();
    ScaffoldMessenger.of(context).showSnackBar(signoutSnackBar);
  }

  void _loginScreen() {
    Navigator.pushNamed(context, '/login');
  }

  void changeState(){
    setState(() {
      sheetOn = !sheetOn;
      sheetController.setSnappingSheetFactor( sheetOn ? 0.20 : 0.03);
    });

  }


  List<SnappingPosition> getSnappingPositions(){
    if(sheetOn){
      return const [SnappingPosition.factor(
        grabbingContentOffset: GrabbingContentOffset.bottom,
        snappingCurve: Curves.easeInExpo,
        snappingDuration: Duration(seconds: 1),
        positionFactor: 0.03,
      ),
        SnappingPosition.factor(
          grabbingContentOffset: GrabbingContentOffset.bottom,
          snappingCurve: Curves.easeInExpo,
          snappingDuration: Duration(seconds: 1),
          positionFactor: 1,
        )
      ];

    }
    else{
      return const [SnappingPosition.factor(
        grabbingContentOffset: GrabbingContentOffset.bottom,
        snappingCurve: Curves.easeInExpo,
        snappingDuration: Duration(seconds: 1),
        positionFactor: 0.08,
      )
      ];
    }


  }
}

class _getGrabbing extends StatelessWidget{
  Function() changeStateFunc;
  _getGrabbing(this.changeStateFunc);

  @override
  Widget build(BuildContext context,) {
    String email = Provider.of<AuthRepository>(context, listen: false).user!.email!;
    return GestureDetector(
        onTap: ()=>changeStateFunc(),
        child: Container(
          alignment: Alignment.centerLeft,
          color:  Color(0xFFCFD8DC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20,), child:
              Text(
                  "Welcome back, $email",
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black,
                    fontSize: 16,
                  )
              )
              )
              ,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.keyboard_arrow_up_sharp),
              ),
            ],
          ),
        )
    );

  }

}

class UserSnappingSheet extends StatefulWidget{
  const UserSnappingSheet({Key? key}) : super(key: key);

  @override
  _UserSnappingSheetState createState() => _UserSnappingSheetState();


}

class _UserSnappingSheetState extends State<UserSnappingSheet>{
  File? image;
  late AuthRepository firebaseUser = Provider.of<AuthRepository>(context, listen: false);
  var uid = "";
  String userEmail = "";




  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          Row(

            children:<Widget> [
              FutureBuilder(
                future: firebaseUser.getUrl(),
                builder: (BuildContext context,
                    AsyncSnapshot<String> snapshot) {
                  return Container(
                    padding: const EdgeInsets.all(5),
                    child: CircleAvatar(
                      radius: 40.0,
                      backgroundColor: const Color(0xffE6E6E6),
                      backgroundImage: (snapshot.data == null)
                          ? null
                          : NetworkImage(snapshot.data!),
                    ),
                  );
                },
              ),

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 40,
                      child: ElevatedButton(
                        child: const Text(
                          "Change avatar",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                        ),
                        onPressed: () => _changeAvatar(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    uid = Provider.of<AuthRepository>(context, listen: false).user!.uid.toString();
    userEmail = Provider.of<AuthRepository>(context, listen: false).user!.email!;
    firebaseUser = Provider.of<AuthRepository>(context, listen: false);
  }



  void _changeAvatar() async{
    FilePickerResult? selected =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpeg',
        'png',
        'jpg',
        'bmp',
        'webp'
        'gif',
      ],
    );
    if (selected == null){
      ScaffoldMessenger.of(context).
      showSnackBar( const SnackBar(
          content: Text('No  image  selected')));

    } else {
      File file = File(selected.files.single.path!);
      firebaseUser.updateImage(file);
    }

  }

}

