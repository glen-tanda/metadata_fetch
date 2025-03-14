import 'dart:convert';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:metadata_fetch/src/parsers/parsers.dart';
import 'package:metadata_fetch/src/utils/util.dart';
import 'package:string_validator/string_validator.dart';

class MetadataFetch {
  /// Fetches a [url], validates it, and returns [Metadata].
  static Future<Metadata?> extract(String url, {Map<String, String>? headers}) async {
    if (!isURL(url)) {
      return null;
    }

    /// Sane defaults; Always return the Domain name as the [title], and a [description] for a given [url]
    final defaultOutput = Metadata();
    defaultOutput.title = getDomain(url);
    defaultOutput.description = url;

    // Make our network call
    final response = await http.get(Uri.parse(url), headers: headers);

    // Return null on failure
    if (response.statusCode != 200) {
      return null;
    }
    
    final headerContentType = response.headers['content-type'];

    if (headerContentType != null && headerContentType.startsWith(r'image/')) {
      defaultOutput.title = '';
      defaultOutput.description = '';
      defaultOutput.image = url;
      return defaultOutput;
    }

    final document = responseToDocument(response);

    if (document == null) {
      return defaultOutput;
    }

    final data = _extractMetadata(document);
    if (data == null) {
      return defaultOutput;
    }

    return data;
  }

  /// Takes an [http.Response] and returns a [html.Document]
  static Document? responseToDocument(http.Response response) {
    if (response.statusCode != 200) {
      return null;
    }

    Document? document;
    try {
      document = parser.parse(utf8.decode(response.bodyBytes));
    } catch (err) {
      return document;
    }

    return document;
  }

  /// Returns instance of [Metadata] with data extracted from the [html.Document]
  /// Provide a given url as a fallback when there are no Document url extracted
  /// by the parsers.
  ///
  /// Future: Can pass in a strategy i.e: to retrieve only OpenGraph, or OpenGraph and Json+LD only
  static Metadata? _extractMetadata(Document document, {String? url}) {
    return MetadataParser.parse(document, url: url);
  }
}
