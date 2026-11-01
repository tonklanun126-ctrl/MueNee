import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/food_scan_result.dart';

abstract interface class FoodAnalysisService {
  Future<FoodScanResult> analyze(FoodScanImage image);
}

class FirebaseFoodAnalysisService implements FoodAnalysisService {
  FirebaseFoodAnalysisService({
    required FirebaseApp app,
    String modelName = const String.fromEnvironment(
      'FOOD_SCAN_MODEL',
      defaultValue: 'gemini-3.7-flash',
    ),
  }) : _model = FirebaseAI.googleAI(app: app).generativeModel(
         model: modelName,
         systemInstruction: Content.system(
           'You estimate one visible meal for a food logging app. '
           'Do not claim medical or laboratory accuracy. Use the visible portion '
           'only, make conservative assumptions, and never invent certainty. '
           'Use a concise Thai food name and a concise Thai portion assumption. '
           'If the image does not clearly show food, set recognizedFood to false.',
         ),
         generationConfig: GenerationConfig(
           temperature: 0.2,
           maxOutputTokens: 512,
           responseMimeType: 'application/json',
           responseSchema: _responseSchema,
         ),
       );

  static final Schema _responseSchema = Schema.object(
    properties: {
      'recognizedFood': Schema.boolean(
        description: 'Whether the image clearly shows food or a meal.',
      ),
      'foodName': Schema.string(
        description: 'Concise Thai name for the visible meal.',
      ),
      'calories': Schema.integer(
        description: 'Estimated kcal for the visible portion.',
        minimum: 0,
        maximum: 10000,
      ),
      'proteinGrams': Schema.number(
        description: 'Estimated protein grams for the visible portion.',
        minimum: 0,
        maximum: 1000,
      ),
      'carbsGrams': Schema.number(
        description: 'Estimated carbohydrate grams for the visible portion.',
        minimum: 0,
        maximum: 1000,
      ),
      'fatGrams': Schema.number(
        description: 'Estimated fat grams for the visible portion.',
        minimum: 0,
        maximum: 1000,
      ),
      'assumption': Schema.string(
        description:
            'Concise Thai note about portion assumptions and uncertainty.',
      ),
    },
    propertyOrdering: [
      'recognizedFood',
      'foodName',
      'calories',
      'proteinGrams',
      'carbsGrams',
      'fatGrams',
      'assumption',
    ],
  );

  final GenerativeModel _model;

  @override
  Future<FoodScanResult> analyze(FoodScanImage image) async {
    final response = await _model
        .generateContent([
          Content.multi([
            const TextPart(
              'Analyze this single meal image. Estimate nutrition for the visible '
              'portion and return only the requested structured result.',
            ),
            InlineDataPart(image.mimeType, image.bytes),
          ]),
        ])
        .timeout(const Duration(seconds: 45));
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException(
        'AI response did not contain structured data',
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI response has an invalid structure');
    }
    return FoodScanResult.fromJson(decoded);
  }
}
