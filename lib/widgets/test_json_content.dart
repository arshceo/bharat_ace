// Test file demonstrating the JSON content format for EngagingStudyContentWidget

const String sampleJsonContent = '''
{
  "content": [
    {
      "type": "flashcard",
      "front": "🌍 What is Economics?",
      "back": "📘 Economics is the study of how people use resources\\n\\n✅ • Studies choices and decisions\\n• Examines resource allocation\\n• Looks at production and consumption\\n• Analyzes market behavior\\n• Studies government policies\\n\\n💡 Example: Choosing between buying a book or saving money"
    },
    {
      "type": "story", 
      "stories": [
        "🏘️ Village Market Day",
        "🥕 Farmer brings vegetables",
        "💰 People trade money for goods", 
        "📈 Prices change with demand",
        "🎯 Everyone benefits from trade"
      ]
    },
    {
      "type": "mnemonic",
      "text": "🧠 **LLPC** = **L**and, **L**abour, **P**hysical Capital, **C**apital! 💪 Remember the 4 FACTORS OF PRODUCTION!"
    },
    {
      "type": "qa",
      "question": "What are the main economic problems every society faces?",
      "answer": "📘 **The Three Basic Economic Questions:**\\n\\n✅ • **What to produce?** - Which goods and services should be made?\\n• **How to produce?** - Which methods and resources to use?\\n• **For whom to produce?** - Who gets the goods and services?\\n\\n**Model Answer:** Every society faces scarcity of resources, so they must decide what goods to produce, how to produce them efficiently, and how to distribute them among people. These three questions form the foundation of all economic systems."
    },
    {
      "type": "summary", 
      "text": "🌟 **Congratulations!** You now understand the basics of Economics! 🚀\\n\\n📚 **Key Takeaways:**\\n• Economics studies choices and resources\\n• Supply and demand affect prices\\n• Trade benefits everyone\\n• Every society faces the same basic questions\\n\\n💪 Keep practicing and you'll master Economics!"
    }
  ]
}
''';

const String simpleJsonArrayContent = '''
[
  {
    "type": "flashcard",
    "front": "💧 Water Cycle",
    "back": "📘 The continuous movement of water on Earth\\n\\n✅ • Evaporation from oceans\\n• Condensation in clouds\\n• Precipitation as rain\\n• Collection in rivers and lakes\\n\\n💡 Example: Rain today might be ocean water from yesterday!"
  },
  {
    "type": "story",
    "stories": [
      "☀️ Sun heats ocean water",
      "💨 Water vapor rises up",
      "☁️ Clouds form in the sky",
      "🌧️ Rain falls to earth",
      "🏞️ Water returns to rivers"
    ]
  },
  {
    "type": "mnemonic",
    "text": "🧠 **ECPC** = **E**vaporation, **C**ondensation, **P**recipitation, **C**ollection! 🌊 The WATER CYCLE steps!"
  }
]
''';
