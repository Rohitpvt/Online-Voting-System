// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'result.dart';
import 'profile_page.dart';
import 'voting_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ElectionScreen extends StatefulWidget {
  final String phone;

  const ElectionScreen({Key? key, required this.phone}) : super(key: key);

  @override
  _ElectionScreenState createState() => _ElectionScreenState();
}

class _ElectionScreenState extends State<ElectionScreen> {
  final PanelController _panelController = PanelController();
  final List<Map<String, String>> elections = [
    {"title": "Delhi CM Election"},
    {"title": "Punjab CM Election"},
    {"title": "Mumbai CM Election"},
    {"title": "Uttar Pradesh CM Election"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  automaticallyImplyLeading: false,
  title: const Padding(
    padding: EdgeInsets.only(left: 8.0),
    child: Text('Elections', style: TextStyle(fontFamily: "urmed", fontSize: 24)),
  ),
  actions: [
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('endDates').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications, size: 28),
            onPressed: () {
              // Show the results panel or handle notification tap
              _showResultsPanel(context);
            },
          );
        }

        final now = DateTime.now();
        final results = snapshot.data!.docs.where((doc) {
          final Timestamp endDateTimestamp = doc['endDate'];
          final DateTime endDate = endDateTimestamp.toDate();
          return now.isAfter(endDate);
        }).map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.phone)
              .collection('viewedResults')
              .snapshots(),
          builder: (context, viewedSnapshot) {
            final viewedResults = viewedSnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};
            final hasNewResults = results.any((resultId) => !viewedResults.contains(resultId));

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, size: 28),
                  onPressed: () {
                    // Show the results panel or handle notification tap
                    _showResultsPanel(context);
                  },
                ),
                if (hasNewResults)
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  )
              ],
            );
          },
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.person, size: 28),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(phone: widget.phone,),
          ),
        );
      },
    ),
  ],
),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffcaa1ff),
              Color(0xff8dafff),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: elections.length,
                itemBuilder: (context, index) {
                  final election = elections[index];
                  final electionTitle = election['title']!;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('endDates')
                        .doc(electionTitle)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: LoadingAnimationWidget.discreteCircle(
                            color: const Color.fromARGB(255, 182, 179, 177),
                            size: 80,
                            secondRingColor: const Color(0xffcaa1ff),
                            thirdRingColor: const Color(0xff8dafff),
                          ),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('No data available for $electionTitle');
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final Timestamp electionDateTimestamp = data['startDate'] as Timestamp;
                      final DateTime electionDate = electionDateTimestamp.toDate();
                      final String formattedDate = "${electionDate.day}.${electionDate.month}.${electionDate.year}";

                      final currentDate = DateTime.now();

                      return Card(
                        color: const Color.fromARGB(255, 240, 239, 239),
                        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          title: Text(
                            electionTitle,
                            style: const TextStyle(
                              fontFamily: "urwbold",
                              fontSize: 21,
                            ),
                          ),
                          subtitle: Text(
                            "Vote Date: $formattedDate",
                            style: const TextStyle(
                              fontFamily: "urmed",
                              fontSize: 17,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 35.0,
                          ),
                          onTap: () {
                            if (currentDate.day == electionDate.day &&
                                currentDate.month == electionDate.month &&
                                currentDate.year == electionDate.year) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VotingScreen(
                                    phone: widget.phone,
                                    electionTitle: electionTitle,
                                  ),
                                ),
                              );
                            } else {
                              _showCustomDialog(context, "Voting is not available right now for: ", electionTitle);
                            }
                          },
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

  // Stream-based function to show the results panel
  void _showResultsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SlidingUpPanel(
          controller: _panelController,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          minHeight: MediaQuery.of(context).size.height * 0.6,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          panel: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('endDates').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: const Color.fromARGB(255, 182, 179, 177),
                    size: 80,
                    secondRingColor: const Color(0xffcaa1ff),
                    thirdRingColor: const Color(0xff8dafff),
                  ),
                );
              }

              final now = DateTime.now();
              final results = snapshot.data!.docs.where((doc) {
                final Timestamp endDateTimestamp = doc['endDate'];
                final DateTime endDate = endDateTimestamp.toDate();
                return now.isAfter(endDate);
              }).map((doc) => doc.id).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.phone)
                    .collection('viewedResults')
                    .snapshots(),
                builder: (context, viewedSnapshot) {
                  final viewedResults = viewedSnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};
                  final unviewedResults = results.where((resultId) => !viewedResults.contains(resultId)).toList();

                  return _buildResultsContent(context, unviewedResults);
                },
              );
            },
          ),
          onPanelSlide: (position) {
            if (position == 0.0) {
              _panelController.close();
            }
          },
        );
      },
    );
  }

  // Content inside the sliding panel
  Widget _buildResultsContent(BuildContext context, List<String> availableResults) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            // leading: IconButton(
            //   icon: Icon(Icons.arrow_back, color: Colors.black),
            //   onPressed: () {
            //     _panelController.close(); // Closes the sliding panel
            //   },
            // ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'urwbold',
                fontSize: 26,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          const Divider(
            color: Color.fromARGB(255, 203, 201, 201),
            thickness: 1.0,
          ),
          const SizedBox(height: 10.0),
          Expanded( 
            child: availableResults.isEmpty
              ? const Center(
                  child: Text(
                    'No new notifications',
                    style: TextStyle(
                      fontFamily: 'urmed',
                      fontSize: 25,
                      color: Colors.black54,
                    ),
                  ),
                )
              :ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: availableResults.length,
              itemBuilder: (context, index) {
                final resultTitle = availableResults[index];

                return Card(
                  color: const Color.fromARGB(255, 240, 239, 239),
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                    title: Text(
                      resultTitle,
                      style: const TextStyle(fontFamily: "urwbold", fontSize: 20),
                    ),
                    subtitle: const Text(
                      'View Result',
                      style: TextStyle(fontFamily: "urmed", fontSize: 17),
                    ),
                    trailing: const Icon(Icons.circle_notifications, size: 35.0, color: Colors.red,),
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultPage(electionTitle: resultTitle),
                        ),
                      );

                      // Mark the result as viewed
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.phone)
                          .collection('viewedResults')
                          .doc(resultTitle)
                          .set({});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomDialog(BuildContext context, String message, String electionTitle) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 200),
                  SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: "urmed",
                        fontSize: 20,
                        color: Color.fromARGB(244, 40, 77, 198),
                      ),
                      children: <TextSpan>[
                        TextSpan(text: message),
                        TextSpan(
                          text: electionTitle,
                          style: const TextStyle(fontFamily: "urwbold"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ).drive(Tween<Offset>(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          )),
          child: child,
        );
      },
    );

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pop();
    });
  }
}
