import 'package:flutter/material.dart';
import 'package:savera/chat.dart';
import 'package:savera/sos.dart';

// void main() => runApp(DisasterApp());

class DisasterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Savera",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: EdgeInsets.all(8),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class DisasterInfo {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> dos;
  final List<String> donts;
  final List<String> preDisaster;
  final List<String> duringDisaster;
  final List<String> postDisaster;

  DisasterInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.dos,
    required this.donts,
    required this.preDisaster,
    required this.duringDisaster,
    required this.postDisaster,
  });
}

// 🌍 Sample Data
final disasters = [
  DisasterInfo(
    name: "Earthquake",
    icon: Icons.public,
    color: Colors.orange,
    dos: [
      "Drop, Cover, and Hold On",
      "Stay away from windows",
      "Keep emergency contacts handy",
    ],
    donts: [
      "Don’t use elevators",
      "Don’t run outside",
      "Don’t stand under doorframes",
    ],
    preDisaster: [
      "Prepare an emergency kit",
      "Secure heavy furniture",
      "Practice drills",
    ],
    duringDisaster: [
      "Stay indoors until shaking stops",
      "If outside, move to open areas",
    ],
    postDisaster: [
      "Check for injuries",
      "Expect aftershocks",
      "Listen to broadcasts",
    ],
  ),
  DisasterInfo(
    name: "Floods",
    icon: Icons.water,
    color: Colors.blue,
    dos: [
      "Move to higher ground",
      "Turn off electricity",
      "Use waterproof bags for valuables",
    ],
    donts: [
      "Don’t walk or drive in floodwaters",
      "Don’t ignore evacuation orders",
    ],
    preDisaster: [
      "Store drinking water",
      "Keep documents safe",
      "Know evacuation routes",
    ],
    duringDisaster: [
      "Stay on rooftops",
      "Avoid floodwater",
      "Listen to warnings",
    ],
    postDisaster: ["Boil water", "Avoid damaged buildings", "Clean everything"],
  ),
  DisasterInfo(
    name: "Fire",
    icon: Icons.local_fire_department,
    color: Colors.red,
    dos: [
      "Stay low to avoid smoke",
      "Use wet cloth on face",
      "Stop, Drop, Roll if on fire",
    ],
    donts: [
      "Don’t open hot doors",
      "Don’t hide under beds",
      "Don’t use elevators",
    ],
    preDisaster: [
      "Install smoke detectors",
      "Keep fire extinguishers",
      "Practice escape routes",
    ],
    duringDisaster: ["Alert others", "Call fire services", "Crawl under smoke"],
    postDisaster: ["Check burns", "Don’t re-enter", "Document damages"],
  ),
  DisasterInfo(
    name: "Tsunami",
    icon: Icons.waves,
    color: Colors.teal,
    dos: [
      "Move inland quickly",
      "Follow evacuation routes",
      "Stay tuned to alerts",
    ],
    donts: ["Don’t go to shore", "Don’t return until safe"],
    preDisaster: [
      "Know tsunami zones",
      "Prepare supplies",
      "Learn warning signs",
    ],
    duringDisaster: [
      "Run to higher ground",
      "Help children/elderly",
      "Avoid rivers",
    ],
    postDisaster: ["Avoid debris", "Wait for all-clear", "Help community"],
  ),
  DisasterInfo(
    name: "Landslide",
    icon: Icons.terrain,
    color: Colors.brown,
    dos: [
      "Move away from landslide path",
      "Stay alert for secondary slides",
      "Listen to emergency services",
    ],
    donts: ["Don’t cross landslide areas", "Don’t return until declared safe"],
    preDisaster: [
      "Avoid building near slopes",
      "Plant vegetation to stabilize soil",
      "Know evacuation routes",
    ],
    duringDisaster: [
      "Run to higher ground",
      "Avoid river valleys",
      "Protect your head",
    ],
    postDisaster: [
      "Check for injuries",
      "Avoid damaged areas",
      "Report hazards to authorities",
    ],
  ),
  DisasterInfo(
    name: "Other Disasters",
    icon: Icons.shield,
    color: Colors.purple,
    dos: ["Keep an emergency kit", "Stay calm", "Follow official instructions"],
    donts: ["Don’t spread rumors", "Don’t panic"],
    preDisaster: [
      "Identify local hazards",
      "Stay informed",
      "Have family plan",
    ],
    duringDisaster: [
      "Stay safe",
      "Assist vulnerable people",
      "Use radios if networks fail",
    ],
    postDisaster: [
      "Help cleanup",
      "Take care of mental health",
      "Prepare for future risks",
    ],
  ),

  DisasterInfo(
    name: "SOS",
    icon: Icons.sos,
    color: Colors.red,
    dos: [],
    donts: [],
    preDisaster: [],
    duringDisaster: [],
    postDisaster: [],
  ),
  DisasterInfo(
    name: "Local Chat",
    icon: Icons.chat,
    color: Colors.blueGrey,
    dos: [],
    donts: [],
    preDisaster: [],
    duringDisaster: [],
    postDisaster: [],
  ),
];

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Disaster Preparedness")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cards per row
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: disasters.length,
          itemBuilder: (context, index) {
            final disaster = disasters[index];
            return GestureDetector(
              onTap: () {
                if (disaster.name == "SOS") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SosPage()),
                  );
                } else if (disaster.name == "Local Chat") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DisasterDetailScreen(disaster: disaster),
                    ),
                  );
                }
                // Navigate to detail screen
              },
              child: Card(
                color: disaster.color.withOpacity(0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(disaster.icon, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      disaster.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DisasterDetailScreen extends StatelessWidget {
  final DisasterInfo disaster;
  DisasterDetailScreen({required this.disaster});

  final List<String> tabs = ["Do's", "Don'ts", "Pre", "During", "Post"];

  List<List<String>> get tabData => [
    disaster.dos,
    disaster.donts,
    disaster.preDisaster,
    disaster.duringDisaster,
    disaster.postDisaster,
  ];

  final List<IconData> icons = [
    Icons.check_circle,
    Icons.cancel,
    Icons.access_time,
    Icons.warning,
    Icons.build,
  ];

  final List<Color> colors = [
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(disaster.name),
          bottom: TabBar(
            isScrollable: false,
            tabs: List.generate(
              tabs.length,
              (index) => Tab(text: tabs[index], icon: Icon(icons[index])),
            ),
          ),
        ),
        body: TabBarView(
          children: List.generate(
            tabs.length,
            (index) => ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: tabData[index].length,
              itemBuilder: (context, i) => Card(
                child: ListTile(
                  // leading: Icon(icons[index], color: colors[index]),
                  title: Text(tabData[index][i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
