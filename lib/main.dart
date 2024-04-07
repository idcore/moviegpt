import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;
import 'package:multi_select_flutter/multi_select_flutter.dart';

void main() {
  runApp(MyApp());
}

final GlobalKey<_MovieListPageState> movieListPageKey = GlobalKey<_MovieListPageState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Movies',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MovieListPage(key:  movieListPageKey),
    );
  }
}

class MovieListPage extends StatefulWidget {

  MovieListPage({Key? key}) : super(key: key); // Accept the key

  @override
  _MovieListPageState createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  late List<Movie> movies;
  late List<Movie> filteredMovies; // The list to display in the GridView
  late List<String> genres;
  late List<String> countries;
  late List<String> rates;



  List<String> selectedGenres = ['All'];
  List<String> selectedCountries = ['All'];
  List<String> selectedRates = ['All'];

  List<String> excludedGenres = [];
  List<String> excludedCountries = [];
  List<String> excludedRates = [];


  RangeValues selectedRating = RangeValues(6,10);
  RangeValues selectedYearRange =
      RangeValues(2000, DateTime.now().year.toDouble());
  bool sortByRatingDescending = true;
  bool sortByYearAscending = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMovies().then((loadedMovies) {
      setState(() {
        movies = loadedMovies;
        filteredMovies =
            applyFiltersAndSort(); // The list to display in the GridView
        genres = getUniqueGenres(movies);
        countries = getUniqueCountries(movies);
        rates = getUniqueRates(movies);
        isLoading = false;
      });
    });
  }

  Future<List<Movie>> loadMovies() async {
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/movie.json');
    final List<String> jsonLines = LineSplitter.split(jsonString).toList();

    final List<Movie> movies = jsonLines.map((line) {
      final Map<String, dynamic> json = jsonDecode(line);
      return Movie.fromJson(json);
    }).toList();

    return movies;
  }

  List<String> getUniqueGenres(List<Movie> movies) {
    final uniqueGenres =
        movies.expand((movie) => movie.genres.split(',')).toSet();
    return ['All', ...uniqueGenres];
  }

  List<String> getUniqueCountries(List<Movie> movies) {
    final uniqueCountries =
        movies.expand((movie) => movie.country.split(',')).toSet();
    return ['All', ...uniqueCountries];
  }

  List<String> getUniqueRates(List<Movie> movies) {
    final uniqueRates =
        movies.expand((movie) => movie.rated.split(',')).toSet();
    return ['All', ...uniqueRates];
  }

  List<Movie> applyFiltersAndSort() {
    List<Movie> filteredMovies = movies.where((movie) {

      final year = int.tryParse(movie.startYear) ?? 0;

      final matchesGenre =
        ( selectedGenres.any((element) => element == 'All') || selectedGenres.any((selectedGenre) =>
            movie.genres.split(',').contains(selectedGenre)) &&
            !excludedGenres.any((excludedGenre) =>
                movie.genres.split(',').contains(excludedGenre)));

      bool matchesCountry;
      if ( movie.country != '' )
      {
        matchesCountry = ( selectedCountries.any((element) => element == 'All') || selectedCountries.any((selectedCountry) =>
      movie.country.split(',').contains(selectedCountry)) &&
      !excludedCountries.any((excludedCountry) =>
      movie.country.split(',').contains(excludedCountry)));
      }
      else
        {
          matchesCountry =  selectedCountries.any((element) => element == 'All');
        };

      final matchesRate =
      ( selectedRates.any((element) => element == 'All') || selectedRates.any((selectedRate) =>
          movie.rated.split(',').contains(selectedRate)) &&
          !excludedRates.any((excludedRate) =>
              movie.rated.split(',').contains(excludedRate)));

      final matchesRating = movie.averageRating >= selectedRating.start
      && movie.averageRating <= selectedRating.end;

      final matchesYear =
          year >= selectedYearRange.start && year <= selectedYearRange.end;

      return matchesGenre &&
          matchesRating &&
          matchesYear &&
          matchesCountry &&
          matchesRate;
    }).toList();

    if (sortByRatingDescending) {
      filteredMovies.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    }

    if (sortByYearAscending) {
      filteredMovies.sort((a, b) => a.startYear.compareTo(b.startYear));
    }

    return filteredMovies;
  }

  void applyFilters() {
    filteredMovies = applyFiltersAndSort();
    setState(() {
      // This method is now responsible for updating filteredMovies
      // with the complete filtering logic incorporated

    });
  }


  Widget buildSortAndFilterPanel() {
    return ExpansionTile(
      title: Text("Filters"),
      leading: Icon(Icons.sort),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              decoration: BoxDecoration(
                //border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Text('Sort by Rating', textAlign: TextAlign.left),
            ),
            Switch(
              value: sortByRatingDescending,
              onChanged: (value) {
                setState(() {
                  sortByRatingDescending = value;
                  //filteredMovies = applyFiltersAndSort();
                });
              },
            ),
            Text(sortByRatingDescending ? 'On' : 'Off'),
                  SizedBox(height:0, width: 40),
                  Text("Select years"),
                  SizedBox(height: 10),
            Container(
                width: 400,
                child:
                  RangeSlider(
                    min: 1940,
                    max: DateTime.now().year.toDouble(),
                    divisions: DateTime.now().year - 1940,
                    labels: RangeLabels(
                      '${selectedYearRange.start.round()}',
                      '${selectedYearRange.end.round()}',
                    ),

                    values: selectedYearRange,
                    onChanged: (RangeValues values) {
                      setState(() {
                        selectedYearRange = values;
                        //filteredMovies = applyFiltersAndSort();
                      });
                    },
                  ),
                ),
            SizedBox(height:0, width: 10),
            Text("Select rating"),
            SizedBox(height: 10),
            Container(
              width: 400,
              child:
            RangeSlider(
              min: 0,
              max: 10,
              divisions: 20,
              labels: RangeLabels(
                '${selectedRating.start}',
                '${selectedRating.end}',
              ),
              values: selectedRating,
              onChanged: (RangeValues values) {
                setState(() {
                  selectedRating = values;
                  //filteredMovies = applyFiltersAndSort();
                });
              },
            ),
            )
                ]

        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MultiSelectDialogField(
                          items: genres
                              .map((genre) => MultiSelectItem(genre, genre))
                              .toList(),
                          title: Text("Include Genres"),
                          buttonText: Text("Include Genres") ,
                          initialValue: selectedGenres,
                          onConfirm: (values) {
                            setState(() {
                              selectedGenres = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 30),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        MultiSelectDialogField(
                          items: genres
                              .map((genre) => MultiSelectItem(genre, genre))
                              .toList(),
                          title: Text("Exclude Genres"),
                          buttonText: Text("Exclude Genres") ,
                          initialValue: excludedGenres,
                          onConfirm: (values) {
                            setState(() {
                              excludedGenres = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MultiSelectDialogField(
                          items: countries
                              .map((country) => MultiSelectItem(country, country))
                              .toList(),
                          title: Text("Include Countries"),
                          buttonText: Text("Include Countries") ,
                          initialValue: selectedCountries,
                          onConfirm: (values) {
                            setState(() {
                              selectedCountries = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 30),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        MultiSelectDialogField(
                          items: countries
                              .map((country) => MultiSelectItem(country, country))
                              .toList(),
                          title: Text("Exclude Countries"),
                          buttonText: Text("Exclude Countries") ,
                          initialValue: excludedCountries,
                          onConfirm: (values) {
                            setState(() {
                              excludedCountries = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MultiSelectDialogField(
                          items: rates
                              .map((rate) => MultiSelectItem(rate, rate))
                              .toList(),
                          title: Text("Include Rates"),
                          buttonText: Text("Include Rates") ,
                          initialValue: selectedRates,
                          onConfirm: (values) {
                            setState(() {
                              selectedRates = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 30),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.blue, width: 2),
                      //borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        MultiSelectDialogField(
                          items: rates
                              .map((rate) => MultiSelectItem(rate, rate))
                              .toList(),
                          title: Text("Exclude Rates"),
                          buttonText: Text("Exclude Rates") ,
                          initialValue: excludedRates,
                          onConfirm: (values) {
                            setState(() {
                              excludedRates = List<String>.from(values);
                              //filteredMovies = applyFiltersAndSort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the button horizontally
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle button press
                // Add the logic for applying filters or any other action
                movieListPageKey.currentState?.applyFilters();


              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue.shade50, // Set button color to blue
              ),
              child: Text('Apply filters'),
            ),
          ],),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildSortAndFilterPanel(),
                Expanded(
                  child: GridView.builder(

                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Increase the count for more columns
                      childAspectRatio:
                          0.6, // You may adjust the aspect ratio as well
                      crossAxisSpacing: 8, // You can adjust spacing if needed
                      mainAxisSpacing: 8, // You can adjust spacing if needed
                    ),
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      return MovieCard(key: ValueKey(movie.tconst), movie: movie);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class MovieCard extends StatefulWidget {
  final Movie movie;
  const MovieCard({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  Future<Movie>? movieFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the movieFuture with null or an initial data point if you have one.
    //movieFuture = Future.value(null);
  }

  Future<Movie> fetchMovie(String movieId) async {
    Movie tmp_movie;
    

    tmp_movie = this.widget.movie;
    return tmp_movie;

  }

  void loadMovie() {
    setState(() {
      movieFuture = fetchMovie(widget.movie.tconst);
    }); // Trigger a rebuild to show the loading indicator
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.movie
          .tconst), // Ensure the key is unique for each visibility detector.
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction > 0 && movieFuture == null) {
          // Adjust the fraction as needed
          // Check if the movie card is visible and movie details aren't already fetched
          loadMovie(); // Fetch the movie details only if the card is sufficiently visible.
        }
      },
      child: FutureBuilder<Movie>(
        future: movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Show a loading spinner
          } else if (snapshot.hasData) {
            final movie = snapshot.data!;
            return Card(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Placeholder for movie poster image
                  Expanded(
                    child: movie.poster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.poster,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Container(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          movie.primaryTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3),
                        // Placeholder for plot text
                        Text(
                          "Genres: ${movie.genres}", // Assuming 'plot' is a field in the Movie class.
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),

                        Text(
                          'Rating: ${movie.averageRating.toStringAsFixed(1)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),

                        Text(
                          'Year: ${movie.startYear}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Rated: ${movie.rated}", // Assuming 'plot' is a field in the Movie class.
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Country: ${movie.country}", // Assuming 'plot' is a field in the Movie class.
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Votes: ${movie.numVotes}", // Assuming 'plot' is a field in the Movie class.
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 3),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Movie details not available'));
          }
        },
      ),
    );
  }
}


class Movie {
  final String tconst;
  final String titleType;
  final String primaryTitle;
  final String originalTitle;
  final bool isAdult;
  final String startYear;
  final String endYear;
  final String runtimeMinutes;
  final String genres;
  final double averageRating;
  final int numVotes;
  String plot;
  String country;
  String poster;
  String director;
  String metascore;
  String language;
  String boxoffice;
  String rated;
  bool enriched;

  Movie({
    required this.tconst,
    required this.titleType,
    required this.primaryTitle,
    required this.originalTitle,
    required this.isAdult,
    required this.startYear,
    required this.endYear,
    required this.runtimeMinutes,
    required this.genres,
    required this.averageRating,
    required this.numVotes,
    required this.plot,
    required this.country,
    required this.poster,
    required this.director,
    required this.metascore,
    required this.language,
    required this.boxoffice,
    required this.rated,
    required this.enriched,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      tconst: json['tconst'],
      titleType: json['titleType'],
      primaryTitle: json['primaryTitle'],
      originalTitle: json['originalTitle'],
      isAdult: json['isAdult'] == true, // Parse 'isAdult' as a boolean
      startYear: json['startYear'],
      endYear: json['endYear'],
      runtimeMinutes: json['runtimeMinutes'],
      genres: json['genres'],
      averageRating: json['averageRating']?.toDouble() ??
          0.0, // Handle null or non-numeric values
      numVotes:
          json['numVotes']?.toInt() ?? 0, // Handle null or non-numeric values
      plot: json['plot'],
      country: json['country'],
      poster: json['poster'],
      director: json['director'],
      metascore: json['metascore'],
      language: json['language'],
      boxoffice: json['boxoffice'],
      rated: json['rated'],
      enriched: json['enriched'] == true,
    );
  }
}
