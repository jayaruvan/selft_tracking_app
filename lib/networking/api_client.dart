import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:selftrackingapp/models/news_article.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final _baseUrl = 'http://covid19.egreen.io:8000';

  Future<bool> registerUser() async {
    final url = '$_baseUrl/user/register';
    final response = await http.post(url);
    // Was this not a success?
    if (response.statusCode != 200) {
      print(
          'Error registering user. Status: ' + response.statusCode.toString());
      return false;
    }
    return true;
  }

  Future<int> getLastMessageId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastMessageId = prefs.getInt("last_message_id");
    if (lastMessageId == null) {
      lastMessageId = 0;
    }

    final url = '$_baseUrl/application/alert/latest';
    print('Get last message ID: $url');
    final response = await http.get(url);
    // Was this not a success?
    if (response.statusCode != 200) {
      print('Error getting latest message ID. Status: ' +
          response.statusCode.toString());
      return -1;
    }
    int lastMessageServerId = jsonDecode(response.body) as int;

    print("l $lastMessageId , lm  $lastMessageServerId");

    if (lastMessageId < lastMessageServerId) {
      prefs.setInt("last_message_id", lastMessageServerId);
      lastMessageId = lastMessageServerId;
    }

    return lastMessageId;
  }

  void getArticleList(startId, endId, StreamSink<NewsArticle> sink) async {
    List<NewsArticle> articles = [];
    for (var i = startId; i <= endId; i++) {
      NewsArticle article = await getMessage(i);
//      articles.add(article);
      sink.add(article);
    }
  }

  Future<NewsArticle> getMessage(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('preferred_language');
    final sharedPrefId = "alert_$lang--$id";
    String alertData = prefs.getString(sharedPrefId);
    print(sharedPrefId);
    if (alertData == null) {
      final url = '$_baseUrl/application/alert/$id/$lang';
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode != 200) {
        print('Error getting message: $id. Status: ' +
            response.statusCode.toString());
        return null;
      }
      print(response.body);
      alertData = utf8.decode(response.bodyBytes);
      prefs.setString(sharedPrefId, alertData);
    }

    // Create message
    var body = jsonDecode(alertData) as Map<String, dynamic>;

    NewsArticle article = NewsArticle.fromJSON(body);
    return article;
  }
}
