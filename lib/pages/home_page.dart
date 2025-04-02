// import 'dart:io';
// import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "LegalAssist",
    profileImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9qdY3-20bWZg2qxx3uLycHi3abvdiNSHJUg&s",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "LegalAssist",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white60,
        elevation: 1,
        shadowColor: Colors.grey.shade100,
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: "Clear Chat",
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildUI(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey.shade300),
            child: const Text(
              "Menu",
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.history),
          //   title: const Text("Chat History"),
          //   onTap: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(
          //         builder: (context) => const ChatHistoryPage(),
          //       ),
          //     );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              // Handle logout here
              // You can add code to clear user data, authentication, etc.
              await FirebaseAuth.instance.signOut();
              // Example: Navigating to the SignInPage after logging out
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _clearChat() {
    setState(() {
      messages.clear();
    });
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String userPrompt = chatMessage.text;

      // Detect if it's a legal query and enhance the prompt
      bool isLegalQuery = _isLegalPrompt(userPrompt);
      String finalPrompt =
          isLegalQuery
              ? "$userPrompt.  for india's law and order context..."
              // ? "$userPrompt. Also, provide relevant acts, sections, punishments, and previous judgments for the Indian context."
              : userPrompt;

      // Check for image inputs
      // List<Uint8List>? images;
      // if (chatMessage.medias?.isNotEmpty ?? false) {
      //   images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      // }

      // Debugging: Print the prompt sent to Gemini
      print("Sending to Gemini: $finalPrompt");

      // Corrected API call
      gemini
          .prompt(parts: [Part.text(finalPrompt)])
          .then((value) {
            // Debugging: Print the full response
            print("Gemini Response: ${value?.output}");

            // Extract response text
            String responseText = value?.output ?? "No response received.";

            // Create a new ChatMessage for Gemini's response
            ChatMessage botMessage = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: responseText,
            );

            // Update UI
            setState(() {
              messages = [botMessage, ...messages];
            });
          })
          .catchError((e) {
            print("Error from Gemini: $e");
          });
    } catch (e) {
      print("Error in _sendMessage: $e");
    }
  }

  // Process Gemini response

  // Function to detect if a query is legal
  bool _isLegalPrompt(String prompt) {
    // Simple keyword-based detection
    List<String> legalKeywords = [
      // General Legal Terms
      "law", "court", "judge", "section", "IPC", "contract", "legal",
      "punishment", "act", "case", "petition", "writ", "tribunal",
      "jurisdiction", "appeal", "bail", "trial", "prosecution",
      "evidence", "affidavit", "lawsuit", "plaintiff", "defendant",
      "statute", "constitution", "lawyer", "advocate", "barrister", "solicitor",
      "subpoena", "plea", "indictment", "witness", "testimony", "defense",
      "prosecutor", "verdict", "sentencing", "remand", "conviction",
      "acquittal",
      "appeal", "review", "misconduct", "disciplinary", "injunction", "damages",

      // Types of Offenses (Criminal & Civil)
      "theft", "robbery", "burglary", "arson", "fraud", "embezzlement",
      "murder", "homicide", "manslaughter", "kidnapping", "extortion",
      "blackmail", "trespass", "assault", "battery", "stalking",
      "harassment", "abduction", "domestic violence", "dowry", "rape",
      "molestation", "defamation", "slander", "libel", "perjury",
      "forgery", "cybercrime", "hacking", "phishing", "identity theft",
      "cheating", "misappropriation", "smuggling", "bribery",
      "corruption", "money laundering", "tax evasion", "drug trafficking",
      "poaching", "vandalism", "rioting", "sedition", "treason",
      "terrorism", "illegal arms", "counterfeiting", "espionage",
      "conspiracy", "prostitution", "human trafficking", "child abuse",
      "rape", "sexual harassment", "child pornography", "bigamy",
      "immigration fraud",
      "abuse of power", "unlawful detention", "racial discrimination",
      "discrimination", "hate speech", "public indecency",
      "environmental crime",
      "illegal logging", "animal cruelty", "illegal gambling",
      "illegal betting",
      "pollution", "toxic waste dumping", "piracy", "illegal mining",

      // Family Law Offenses
      "divorce", "alimony", "child custody", "adultery",
      "bigamy", "dowry harassment", "maintenance", "child adoption",
      "spousal abuse", "child support", "guardianship", "parental rights",
      "parental alienation", "family dispute", "marriage annulment",
      "inheritance", "will", "estate dispute", "inheritance fraud",
      "will contest",

      // Property and Financial Crimes
      "land dispute", "encroachment", "illegal construction", "fraudulent sale",
      "property rights", "property tax evasion", "real estate fraud",
      "mortgage fraud", "title dispute", "land grab", "foreclosure",
      "public land misuse", "unlawful demolition", "money laundering",
      "embezzlement",
      "tax fraud", "financial fraud", "mismanagement", "bankruptcy fraud",
      "misuse of company funds", "stock market manipulation",
      "corporate crime", "corporate espionage", "unfair competition",
      "trade secret theft", "false advertising", "consumer protection",

      // Environmental and Social Offenses
      "pollution", "illegal dumping", "climate change denial", "eco-terrorism",
      "illegal hunting", "deforestation", "wildlife trafficking",
      "illegal fishing",
      "water contamination", "illegal mining", "illegal sand mining",
      "corruption in environment",
      "wildlife poaching", "endangered species law", "public health law",
      "unsanitary conditions", "unsustainable farming practices",
      "genetically modified organisms",

      // Labour and Employment Law
      "workplace discrimination", "harassment", "unfair dismissal",
      "workplace safety", "overtime pay", "employment contract", "wage theft",
      "minimum wage violation", "union rights", "strike",
      "worker's compensation",
      "whistleblowing", "sexual harassment at work", "illegal child labor",
      "employment fraud", "independent contractor misclassification",
      "employment benefits", "unpaid leave", "working hours violation",
      "workplace bullying", "union busting", "labor union violations",

      // Corporate and Business Law
      "corporate governance", "merger and acquisition fraud", "insider trading",
      "shareholder disputes", "business fraud", "antitrust law",
      "trade regulation",
      "intellectual property theft", "patent infringement",
      "trademark violation",
      "copyright infringement", "contract breach", "franchise law",
      "business bankruptcy", "commercial disputes", "unfair trade practices",
      "business tax evasion", "labor law violation", "advertising fraud",

      // Cyber and Technology Law
      "data breach", "hacking", "cyberattack", "identity theft",
      "phishing", "DDoS attack", "cyberbullying", "data privacy violation",
      "intellectual property theft", "software piracy", "cyber espionage",
      "e-commerce fraud", "cybersecurity", "digital rights",
      "social media abuse", "misuse of personal data", "IoT vulnerability",
      "AI regulation", "blockchain law", "online harassment",

      // Immigration and International Law
      "visa fraud", "immigration violation", "illegal immigration",
      "refugee law", "asylum seeker", "naturalization", "deportation",
      "immigration detention", "international treaty", "extradition",
      "war crimes", "international human rights law", "refugee status",
      "international trade law", "embargo violation",
      "international arbitration",
      "UN convention violations", "terrorist financing", "border security",

      // Administrative and Government Law
      "public policy", "administrative review", "government accountability",
      "public procurement fraud", "election fraud", "graft",
      "government corruption",
      "anti-money laundering", "public official misconduct",
      "whistleblower protection",
      "transparency", "election laws", "public funding misuse", "audit fraud",
      "civil service violations", "intelligence gathering law",
    ];

    return legalKeywords.any(
      (keyword) => prompt.toLowerCase().contains(keyword),
    );
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(url: file.path, fileName: "", type: MediaType.image),
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat History")),
      body: const Center(child: Text("Chat history will be displayed here.")),
    );
  }
}
