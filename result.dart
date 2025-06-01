import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultPage extends StatelessWidget {
  final String electionTitle;

  ResultPage({required this.electionTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$electionTitle Results',
          style: const TextStyle(fontFamily: "urmed", fontSize: 22),
        ),
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
            const SizedBox(height: 10), // Add gap between AppBar and the first card
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('endDates')
                    .doc(electionTitle)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('votes')
                        .where('State', isEqualTo: electionTitle) // Filter votes by electionTitle
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No results available",
                            style: TextStyle(color:Colors.white,fontSize:  30, fontFamily: "urmed"),
                          ),
                        );
                      }  

                      var votes = snapshot.data!.docs;
                      var voteCounts = <String, int>{};
                      var candidateNames = <String, String>{};
                      var partyNames = <String, String>{};
                      var partyIcons = <String, String>{};
                      int totalVotes = votes.length; // Total number of votes

                      // Count votes for each candidate and store candidate names, party names, and icons
                      for (var vote in votes) {
                        var candidateId = vote['candidateId'];
                        var candidateName = vote['candidateName'];
                        var partyName = vote['PartyName'];
                        var partyIcon = vote['PartyIcon'];

                        // Count the votes for each candidate
                        if (voteCounts.containsKey(candidateId)) {
                          voteCounts[candidateId] = voteCounts[candidateId]! + 1;
                        } else {
                          voteCounts[candidateId] = 1;
                          candidateNames[candidateId] = candidateName; // Store candidate name
                          partyNames[candidateId] = partyName; // Store party name
                          partyIcons[candidateId] = partyIcon; // Store party icon URL
                        }
                      }

                      // Sort candidates by vote count
                      var sortedCandidates = voteCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      // Get the highest percentage candidate
                      var highestVoteEntry = sortedCandidates.first;
                      var highestCandidateId = highestVoteEntry.key;
                      var highestVoteCount = highestVoteEntry.value;
                      var highestCandidateName = candidateNames[highestCandidateId] ?? "Unknown Candidate";
                      var highestPartyName = partyNames[highestCandidateId] ?? "Unknown Party";
                      var highestPartyIcon = partyIcons[highestCandidateId] ?? "";
                      var highestVotePercentage = (highestVoteCount / totalVotes * 100).toStringAsFixed(0); // Calculate percentage

                      return ListView.builder(
                        itemCount: sortedCandidates.length,
                        itemBuilder: (context, index) {
                          var candidateId = sortedCandidates[index].key;
                          var voteCount = sortedCandidates[index].value;
                          var candidateName = candidateNames[candidateId] ?? "Unknown Candidate";
                          var partyName = partyNames[candidateId] ?? "Unknown Party";
                          var partyIcon = partyIcons[candidateId] ?? "";
                          var votePercentage = (voteCount / totalVotes * 100).toStringAsFixed(0); // Calculate percentage

                          // Check if this is the highest vote percentage winner
                          if (candidateId == highestCandidateId) {
                            // Return the special winner card
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "WINNER",
                                      style: TextStyle(
                                        fontFamily: "urmed",
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(highestPartyIcon),
                                      radius: 50, // Larger size for the winner
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      highestPartyName,
                                      style: const TextStyle(
                                        fontFamily: "urmed",
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      highestCandidateName,
                                      style: const TextStyle(
                                        fontFamily: "urmed",
                                        fontSize: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$highestVotePercentage%',
                                      style: const TextStyle(
                                        fontFamily: "urmed",
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Other candidates' regular cards
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Party Icon on the left side
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(partyIcon), // Load party icon from the URL
                                    radius: 25,
                                  ),
                                  const SizedBox(width: 12), // Add space between the icon and the text

                                  // Candidate and Party Names in the middle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          candidateName,
                                          style: const TextStyle(fontFamily: "urmed", fontSize: 19),
                                        ),
                                        Text(
                                          partyName,
                                          style: const TextStyle(
                                              fontFamily: "urmed",
                                              fontSize: 17,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Vote percentage on the right side
                                  Text(
                                    '$votePercentage%',
                                    style: const TextStyle(fontFamily: "urmed", fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
}
