import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

const String APIKey = 'LIVDSRZULELA';
const String searchEndpoint = 'https://g.tenor.com/v1/search';
const String autocompleteEndpoint = 'https://g.tenor.com/v1/autocomplete';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenor Pictures',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: GifSearchHomePage(),
    );
  }
}

class GifSearchHomePage extends StatefulWidget {
  @override
  _GifSearchHomePageState createState() => _GifSearchHomePageState();
}

class _GifSearchHomePageState extends State<GifSearchHomePage> {
  List<String> suggestions = [];
  List<dynamic> gifs = [];
  String? nextPos;
  bool _showSuggestions = true;

  TextEditingController _searchController = TextEditingController();

  Future<void> searchGifs(String query, {String? pos}) async {
    final url =
        'https://g.tenor.com/v1/search?q=$query&key=$APIKey&limit=8${pos != null ? '&pos=$pos' : ''}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'];

      setState(() {
        if (pos == null) {
          gifs = results;
        } else {
          gifs.insertAll(0, results); // Add new GIFs to the beginning of the list
        }
        nextPos = data['next'];
      });
    } else {
      print('Error searching GIFs: ${response.statusCode}');
    }
  }

  void autocompleteSearch(String query) async {
    final url = '$autocompleteEndpoint?q=$query&key=$APIKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        suggestions = List<String>.from(data['results']);
      });
    } else {
      print(
          'Error retrieving autocomplete suggestions: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenor Pictures'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  autocompleteSearch(value);
                } else {
                  setState(() {
                    suggestions = [];
                  });
                }
              },
              onSubmitted: (value) {
                setState(() {
                  _showSuggestions = false;
                });
                searchGifs(value);
              },
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSuggestions = false;
                    });
                    searchGifs(_searchController.text);
                  },
                ),
              ),
            ),
          ),
          // Highlighted changes start
          _showSuggestions && suggestions.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        title: Text(suggestion),
                        onTap: () {
                          setState(() {
                            _showSuggestions = false;
                          });
                          _searchController.text = suggestion;
                          searchGifs(suggestion);
                        },
                      );
                    },
                  ),
                )
              : SizedBox(),
          // Highlighted changes end
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: gifs.length,
              itemBuilder: (context, index) {
                final gif = gifs[index];
                final url = gif['media'][0]['tinygif']['url'];

                return CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                );
              },
            ),
          ),
          nextPos != null
              ? ElevatedButton(
                  child: Text('Load More'),
                  onPressed: () => searchGifs(_searchController.text, pos: nextPos),
                )
              : SizedBox(),
        ],
      ),
    );
  }
}
