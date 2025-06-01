// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'result.dart';

class VotingScreen extends StatefulWidget {
  final String electionTitle;
  final String phone;

  const VotingScreen({
    super.key,
    required this.phone,
    required this.electionTitle,
  });

  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  String? selectedCandidateId;
  String? selectedCandidateName;
  bool isCheckboxChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.electionTitle,
            style: const TextStyle(fontFamily: "urmed", fontSize: 24)),
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.bar_chart_outlined, size: 28),
            ),
            onPressed: () {
              _checkResultAvailability(context);
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
            const Padding(padding: EdgeInsets.only(top: 10)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.electionTitle)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var candidates = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      var candidate = candidates[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Image.network(
                                      candidate['iconUrl'],
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: LoadingAnimationWidget
                                              .discreteCircle(
                                            color: const Color.fromARGB(
                                                255, 216, 214, 213),
                                            size: 80,
                                            secondRingColor:
                                                const Color(0xffcaa1ff),
                                            thirdRingColor:
                                                const Color(0xff8dafff),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.error),
                                    ),
                                  ),
                                  Radio<String>(
                                    value: candidate.id,
                                    groupValue: selectedCandidateId,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCandidateId = value;
                                        isCheckboxChecked = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              title: Text(candidate['name'],
                                  style: const TextStyle(
                                      fontFamily: "urmed", fontSize: 18)),
                              subtitle: Text(candidate['party'],
                                  style: const TextStyle(
                                      fontFamily: "urmed", fontSize: 16)),
                              trailing: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  _showCandidateDetails(candidate);
                                },
                              ),
                            ),
                            if (selectedCandidateId == candidate.id)
                              CheckboxListTile(
                                title: Text(
                                  "I have selected ${candidate['name']} from ${candidate['party']} as my vote.",
                                  style: const TextStyle(
                                      fontFamily: "urmed", fontSize: 18),
                                ),
                                value: isCheckboxChecked,
                                onChanged: (value) {
                                  setState(() {
                                    isCheckboxChecked = value ?? false;
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCandidateId != null && isCheckboxChecked
                      ? () {
                          _submitVote(selectedCandidateId!);
                        }
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('VOTE',
                        style: TextStyle(fontFamily: "urmed", fontSize: 18)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkResultAvailability(BuildContext context) {
    FirebaseFirestore.instance
        .collection('endDates')
        .doc(widget.electionTitle)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        var endDate = (snapshot['endDate'] as Timestamp).toDate();
        var currentDate = DateTime.now();

        if (currentDate.isBefore(endDate)) {
          _showResultsNotAvailableDialog(endDate);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                electionTitle: widget.electionTitle,
              ),
            ),
          );
        }
      }
    }).catchError((error) {
      print('Error checking result availability: $error');
    });
  }

  void _showResultsNotAvailableDialog(DateTime endDate) {
    String formattedDate = "${endDate.day}/${endDate.month}/${endDate.year}";

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 15,bottom: 25,right: 15,left: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 150),
                  const Text(
                    'Results Not Available Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "urmed",
                        fontSize: 24,
                        color: Colors.black),
                  ),
                  Text(
                    'Results will be available on: $formattedDate',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: "urmed",
                        fontSize: 18,
                        color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          const Color(0xff4e5dc1), // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                    ),
                    child: const Text('OK',
                        style: TextStyle(fontFamily: "urmed", fontSize: 20)),
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
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  void _showCandidateDetails(DocumentSnapshot candidate) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: AlertDialog(
            title: Center(
                child: Text(candidate['name'],
                    style: const TextStyle(fontFamily: "urmed", fontSize: 28))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.network(
                    candidate['profilePictureUrl'],
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: LoadingAnimationWidget.discreteCircle(
                          color: const Color.fromARGB(255, 182, 179, 177),
                          size: 80,
                          secondRingColor: const Color(0xffcaa1ff),
                          thirdRingColor: const Color(0xff8dafff),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 50),
                  ),
                ),
                const SizedBox(height: 15),
                Text("Age: ${candidate['age']}",
                    style: const TextStyle(fontFamily: "urmed", fontSize: 19)),
                Text("Education: ${candidate['education']}",
                    style: const TextStyle(fontFamily: "urmed", fontSize: 19)),
                Text("Party: ${candidate['party']}",
                    style: const TextStyle(fontFamily: "urmed", fontSize: 19)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close',
                    style: TextStyle(fontFamily: "urmed", fontSize: 18)),
              ),
            ],
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
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  void _submitVote(String candidateId) {
    String electionTitle;
    electionTitle = widget.electionTitle;
    // Get candidate name from the selected candidate
    var selectedCandidate = FirebaseFirestore.instance
        .collection(widget.electionTitle)
        .doc(candidateId)
        .get();

    selectedCandidate.then((DocumentSnapshot candidateSnapshot) {
      String candidateName = candidateSnapshot['name'];
      String candidateIcon = candidateSnapshot['profilePictureUrl'];
      String PartyName = candidateSnapshot['party'];
      String PartyIcon = candidateSnapshot['iconUrl'];

      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phone)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          // Convert age from string to int
          int age = int.parse(documentSnapshot['Age']);

          if (age < 18) {
            // Show dialog if user is not eligible to vote
            _showEligibilityDialog();
          } else {
            // Check if user has already voted
            if (documentSnapshot['hasVoted $electionTitle'] == 'true') {
              _showCustomDialog(
                  'You have already voted and are ineligible to vote again.',
                  success: false);
            } else {
              // Update voting status and record vote
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.phone)
                  .update({
                'hasVoted $electionTitle': 'true',
              });

              FirebaseFirestore.instance.collection('votes').add({
                'candidateId': candidateId,
                'candidateName': candidateName,
                'candidateIcon': candidateIcon,
                'PartyName': PartyName,
                'PartyIcon': PartyIcon,
                'State': electionTitle,
                'timestamp': FieldValue.serverTimestamp(),
              }).then((_) {
                _showCustomDialog('Vote submitted successfully!',
                    success: true);
              }).catchError((error) {
                _showCustomDialog('Failed to submit vote: $error',
                    success: false);
              });
            }
          }
        } else {
          _showCustomDialog('Failed to fetch user details', success: false);
        }
      }).catchError((error) {
        _showCustomDialog('Failed to check voting status: $error',
            success: false);
      });
    }).catchError((error) {
      _showCustomDialog('Failed to fetch candidate details: $error',
          success: false);
    });
  }

  void _showEligibilityDialog() {
    // Create a future to close the dialog after 5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 150),
                  SizedBox(height: 15),
                  Text(
                    'You are not eligible to Vote Yet :)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "urmed", fontSize: 24, color: Colors.black),
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
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  void _showCustomDialog(String message, {required bool success}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop(true);
        });
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  success
                      ? Image.network(
                          "https://firebasestorage.googleapis.com/v0/b/voting-469a3.appspot.com/o/vote.png?alt=media&token=02f727df-23fb-408c-b228-fcadc9fd9e6f",
                          height: 200,
                        ) // Make sure to add the tick gif to your assets
                      : const Icon(Icons.error, color: Colors.red, size: 150),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: "urmed",
                        fontSize: 20,
                        color: Color.fromARGB(244, 40, 77, 198)),
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
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }
}
