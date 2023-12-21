import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController textEditingController = TextEditingController();
  File? serviceAccountFile;
  Map<String, dynamic>? credential;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      serviceAccountFile = File(result.files.single.path!);
      textEditingController.text = serviceAccountFile!.path;
      setState(() {});
    }
  }

  Future<void> obtainCredentials() async {
    var accountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountFile!.readAsStringSync()));
    List<String> scopes = ["https://www.googleapis.com/auth/firebase.messaging"];

    var client = http.Client();
    AccessCredentials accessCredential = await obtainAccessCredentialsViaServiceAccount(
      accountCredentials,
      scopes,
      client,
    );

    setState(() {
      credential = accessCredential.toJson();
    });
    client.close();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FCM Token Retriever"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: "Service account",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: pickFile,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: serviceAccountFile != null ? obtainCredentials : null,
              child: const Text("Generate"),
            ),
            if (credential != null) ...[
              const SizedBox(height: 24),
              SelectableText(getPrettyJSONString(credential)),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Copy"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String getPrettyJSONString(jsonObject) {
  var encoder = const JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
