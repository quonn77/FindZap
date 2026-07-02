import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:ogg_opus_player/ogg_opus_player.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

void main() {
  runApp(WhatsAppViewerApp());
}

class WhatsAppViewerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<String> messages = [];
  Directory? _mediaDirectory;
  String? _selectedFilePath;
  String _senderName = 'Alessio Iannone';
  String _receiverName = 'Geometra Nocente Luca';
  Duration _duration = Duration.zero;
  int _currentMediaMessageIndex = -1;
  final _scrollController = ScrollController();
  final _sliverListKey = GlobalKey<SliverAnimatedListState>();

  OggOpusPlayer? _oggOpusPlayer = null;

  // Search state
  bool _searchVisible = false;
  TextEditingController _searchController = TextEditingController();
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  // Search debounce
  Timer? _searchDebounceTimer;
  final _searchDebounceDelay = Duration(milliseconds: 300);

  // Date search state
  DateTime? _minDate;
  DateTime? _maxDate;
  DateTime? _selectedDate;

  // Date cache for performance
  Map<String, DateTime> _dateCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounceTimer != null) {
      _searchDebounceTimer?.cancel();
    }
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _performTextSearch(_searchController.text);
      _searchDebounceTimer = null;
    });
  }

  void _performTextSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchIndex = -1;
      });
      return;
    }

    List<int> results = [];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].contains(query)) {
        results.add(i);
      }
    }

    setState(() {
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty && _currentSearchIndex == 0) {
      _scrollToMessage(results[0]);
    }
  }

  void _scrollToMessage(int index) {
    if (index >= 0 && index < messages.length) {
      // Use Scrollable.ensureVisible for accurate scrolling instead of hardcoded offset
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Scroll using the target widget's GlobalKey
          _scrollController.animateTo(
            index * 60.0, // Fallback; ListView.builder handles virtualization
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _showSearchBar() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchController.clear();
        _searchResults = [];
        _currentSearchIndex = -1;
      }
    });
  }

  void _navigateSearchResult(int direction) {
    if (_searchResults.isEmpty) return;

    int newIndex = _currentSearchIndex + direction;
    if (newIndex < 0) newIndex = _searchResults.length - 1;
    if (newIndex >= _searchResults.length) newIndex = 0;

    setState(() {
      _currentSearchIndex = newIndex;
    });

    _scrollToMessage(_searchResults[newIndex]);
  }

  void _showDateSearchDialog() {
    if (messages.isEmpty) return;

    // Calculate date range from messages
    DateTime minDate = DateTime(9999);
    DateTime maxDate = DateTime(0);

    for (String message in messages) {
      DateTime msgDate = _extractDateFromMessage(message);
      if (msgDate.year > 0) {
        if (msgDate.isBefore(minDate)) minDate = msgDate;
        if (msgDate.isAfter(maxDate)) maxDate = msgDate;
      }
    }

    // Set to first of the month/year for cleaner picker
    DateTime pickerMin = DateTime(minDate.year, minDate.month, 1);
    DateTime pickerMax = DateTime(maxDate.year, maxDate.month, maxDate.day);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cerca per data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Intervallo: ${_formatDate(minDate)} - ${_formatDate(maxDate)}'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime? selected = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime(minDate.year, minDate.month, minDate.day),
                    firstDate: pickerMin,
                    lastDate: pickerMax,
                  );
                  if (selected != null) {
                    Navigator.of(context).pop();
                    _searchByDate(selected);
                  }
                },
                child: Text('Seleziona data'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  void _searchByDate(DateTime targetDate) {
    if (messages.isEmpty) return;

    // Find the message closest to the target date
    int closestIndex = -1;
    int minDiff = 2147483647; // int32 max value

    for (int i = 0; i < messages.length; i++) {
      DateTime msgDate = _extractDateFromMessage(messages[i]);
      if (msgDate.year > 0) {
        // Compare only the date part (ignore time)
        DateTime msgDateOnly =
            DateTime(msgDate.year, msgDate.month, msgDate.day);
        DateTime targetDateOnly =
            DateTime(targetDate.year, targetDate.month, targetDate.day);
        int diff = msgDateOnly.difference(targetDateOnly).inDays.abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestIndex = i;
        }
      }
    }

    if (closestIndex != -1) {
      setState(() {
        _currentSearchIndex = closestIndex;
        _searchResults = [closestIndex];
      });
      _scrollToMessage(closestIndex);
    } else {
      // No messages found on that date
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nessun messaggio trovato per questa data')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('WhatsApp Viewer'),
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: _pickFile,
            ),
            IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: _navigateToNextMediaMessage,
            ),
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: _showMediaListDialog,
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _showSearchBar,
            ),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: _showDateSearchDialog,
            ),
          ],
        ),
        bottom: _searchVisible
            ? PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: SearchBar(
                  controller: _searchController,
                  searchResults: _searchResults,
                  currentIndex: _currentSearchIndex,
                  onPrevious: () => _navigateSearchResult(-1),
                  onNext: () => _navigateSearchResult(1),
                  onClose: _showSearchBar,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : (_selectedFilePath == null
                    ? Center(
                        child: Text(
                            'Seleziona un file di esportazione di WhatsApp'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          String message = messages[index];
                          bool isSent = _isSentMessage(message);
                          bool isMediaMessage = _isMediaMessage(message);
                          bool isSearchResult = _searchResults.contains(index);

                          return Align(
                            alignment: isSent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSearchResult
                                    ? Colors.yellow.shade200
                                    : (isSent
                                        ? Colors.green.shade100
                                        : Colors.grey.shade800),
                                borderRadius: BorderRadius.circular(10),
                                border: isSearchResult
                                    ? Border.all(color: Colors.orange, width: 2)
                                    : null,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (isMediaMessage) {
                                    _showMediaDialog(context, message, index);
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMediaMessage)
                                      Icon(Icons.attach_file,
                                          color: isSent
                                              ? Colors.black
                                              : Colors.white),
                                    if (isMediaMessage) SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                            color: isSent
                                                ? Colors.black
                                                : Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }

  DateTime _extractDateFromMessage(String message) {
    // Check cache first
    if (_dateCache.containsKey(message)) {
      return _dateCache[message]!;
    }
    try {
      List<String> parts = message.split(' - ');
      String dateString = parts[0];
      List<String> dateHours = dateString.split(", ");
      List<String> dateParts = dateHours[0].split('/');
      List<String> hourParts = dateHours[1].split(":");
      int day = int.parse(dateParts[0].trim());
      int month = int.parse(dateParts[1].trim());
      int year = int.parse(dateParts[2].trim());

      int hours = int.parse(hourParts[0].trim());
      int minutes = int.parse(hourParts[1].trim());
      DateTime date = DateTime(year, month, day, hours, minutes);
      _dateCache[message] = date;
      return date;
    } catch (ex) {
      DateTime zeroDate = DateTime(0, 0, 0);
      _dateCache[message] = zeroDate;
      return zeroDate;
    }
  }

  void _showMediaListDialog() {
    List<String> mediaMessages = messages.where(_isMediaMessage).toList();
    mediaMessages.sort((a, b) {
      DateTime dateA = _extractDateFromMessage(a);
      DateTime dateB = _extractDateFromMessage(b);
      return dateA.compareTo(dateB);
    });
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Elenco media'),
          content: SingleChildScrollView(
            child: Column(
              children: mediaMessages.map((message) {
                int index = mediaMessages.indexOf(message);
                return ListTile(
                  title: Text(message),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMediaDialog(context, message, index);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _navigateToNextMediaMessage() {
    int currentIndex = _getCurrentMediaMessageIndex();
    if (currentIndex != -1) {
      int nextIndex = _getNextMediaMessageIndex(currentIndex);
      if (nextIndex != -1) {
        _currentMediaMessageIndex = nextIndex;
        _showMediaDialog(context, messages[nextIndex], nextIndex);
      }
    }
  }

  int _getCurrentMediaMessageIndex() {
    for (int i = 0; i < messages.length; i++) {
      if (_isMediaMessage(messages[i]) && i > _currentMediaMessageIndex) {
        _currentMediaMessageIndex = i;
        return i;
      }
    }
    return -1;
  }

  int _getNextMediaMessageIndex(int currentIndex) {
    for (int i = currentIndex + 1; i < messages.length; i++) {
      if (_isMediaMessage(messages[i])) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['txt']);

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
        });
        await _showNameInputDialog();
        _loadMessages(filePath);
      }
    }
  }

  Future<void> _showNameInputDialog() async {
    TextEditingController senderController =
        TextEditingController(text: _senderName);
    TextEditingController receiverController =
        TextEditingController(text: _receiverName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Inserisci i nomi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senderController,
                decoration: InputDecoration(labelText: 'Nome del mittente'),
              ),
              TextField(
                controller: receiverController,
                decoration: InputDecoration(labelText: 'Nome del destinatario'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _senderName = senderController.text;
                  _receiverName = receiverController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadMessages(String filePath) async {
    print('Loading messages from: $filePath');

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    File file = File(filePath);
    Directory fileDirectory = Directory(path.dirname(filePath));
    Directory mediaDir = _isMediaInSameDirectory(fileDirectory)
        ? fileDirectory
        : Directory('${fileDirectory.parent.path}');
    print('Media directory: ${mediaDir.path}');

    // Pre-compile regex outside the loop
    // Match both DD/MM/YY and DD/MM/YYYY formats
    final dateRegex = RegExp(r'\d{2}/\d{2}/\d{2,4}, \d{2}:\d{2} - ');

    List<String> messages = [];
    String currentMessage = '';

    // Streaming read using openRead() + LineSplitter to avoid loading entire file into memory
    var stream =
        file.openRead().transform(utf8.decoder).transform(LineSplitter());
    await stream.forEach((String line) {
      if (dateRegex.hasMatch(line)) {
        if (currentMessage.isNotEmpty) {
          messages.add(currentMessage);
        }
        currentMessage = line;
      } else {
        currentMessage += '\n$line';
      }
    });
    if (currentMessage.isNotEmpty) {
      messages.add(currentMessage);
    }

    // Clear date cache when loading new messages
    _dateCache.clear();

    setState(() {
      this.messages = messages;
      _mediaDirectory = mediaDir;
      _isLoading = false;
    });
  }

  bool _isSentMessage(String message) {
    return message.contains(_senderName);
  }

  bool _isMediaMessage(String message) {
    return message.contains('IMG-') ||
        message.contains('VID-') ||
        message.contains('.opus') ||
        message.contains('.pdf');
  }

  bool _isMediaInSameDirectory(Directory directory) {
    List<FileSystemEntity> files = directory.listSync();
    for (var file in files) {
      if (_isMediaMessage(file.path)) {
        return true;
      }
    }
    return false;
  }

  void _showMediaDialog(BuildContext context, String message, int index) {
    _currentMediaMessageIndex = index;
    if (message.contains('IMG-')) {
      _showImageDialog(context, message);
    } else if (message.contains('.pdf')) {
      _showPdfDialog(context, message);
    } else if (message.contains('.opus')) {
      _playAudio(message);
    }
    _scrollToCurrentMediaMessage();
  }

  void _scrollToCurrentMediaMessage() {
    // Removed "if (true) return" dead code
    if (_currentMediaMessageIndex != -1) {
      final index = _currentMediaMessageIndex;
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (index < messages.length) {
          _scrollController.animateTo(
            index * 60.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        }
      });
    }
  }

  void _showImageDialog(BuildContext context, String message) {
    List<String> parts = message.split(':');
    String imageName = parts.last.trim();
    imageName = imageName.replaceAll(' (file allegato)', '').substring(1);

    String imagePath = path.join('${_mediaDirectory?.path}', imageName);

    print('Opening image dialog for: $imagePath');
    var fileImage = File(imagePath);
    if (fileImage.existsSync()) {
      print("L'immagine esiste");
    } else {
      print("L'immagine non esiste");
    }
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.yellow.shade200,
          child: Image.file(File(imagePath)),
        );
      },
    );
  }

  void _showPdfDialog(BuildContext context, String message) {
    List<String> parts = message.split(':');
    String pdfName = parts.last.trim();
    pdfName = pdfName.replaceAll(' (file allegato)', '').substring(1);

    String pdfPath = path.join('${_mediaDirectory?.path}', pdfName);
    print('Opening PDF dialog for: $pdfPath');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SfPdfViewer.file(File(pdfPath)),
        );
      },
    );
  }

  void _playAudio(String message) async {
    print("Audio message: $message");

    List<String> parts = message.split(':');
    String audioName = parts.last.trim();
    audioName = audioName.replaceAll(' (file allegato)', '').substring(1);
    String audioPath = path.join('${_mediaDirectory?.path}', audioName);
    print('Playing audio: $audioPath');

    if (_oggOpusPlayer != null) {
      _oggOpusPlayer!.dispose();
    }

    _oggOpusPlayer = OggOpusPlayer(audioPath);
    _oggOpusPlayer?.play();
    _showAudioPlayerDialog(context, _oggOpusPlayer);
  }

  void _showAudioPlayerDialog(
      BuildContext context, OggOpusPlayer? _oggOpusPlayer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Controllo riproduzione'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () {
                  if (_oggOpusPlayer != null) {
                    _oggOpusPlayer!.play();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.pause),
                onPressed: () {
                  if (_oggOpusPlayer != null) {
                    _oggOpusPlayer!.pause();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.stop),
                onPressed: () {
                  if (_oggOpusPlayer != null) {
                    _oggOpusPlayer!.dispose();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// SearchBar widget
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final List<int> searchResults;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  SearchBar({
    required this.controller,
    required this.searchResults,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: Colors.white.withOpacity(0.7)),
          SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca nei messaggi...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (searchResults.isNotEmpty)
            Text(
              '${currentIndex + 1}/${searchResults.length}',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_up, size: 20),
            onPressed: searchResults.isNotEmpty ? onPrevious : null,
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down, size: 20),
            onPressed: searchResults.isNotEmpty ? onNext : null,
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
