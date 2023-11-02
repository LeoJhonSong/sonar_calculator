import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
        title: '声呐方程计算器',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const MyHomePage(),
      )
  );
}

class Term {
  Term({required this.name, this.value = 0, required this.weight});

  String name;
  double value;
  double weight;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Map<String, Term> _terms = {
    'SL': Term(name: 'SL', weight: 1.0),
    'TL': Term(name: 'TL', weight: -2.0),
    'TS': Term(name: 'TS', weight: 1.0),
    'NL': Term(name: 'NL', weight: -1.0),
    'DI': Term(name: 'DI', weight: 1.0),
    'DT': Term(name: 'DT', weight: -1.0),
  };

  void _handleSetValue(String name, double value) {
    setState(() {
      _terms[name]!.value = value;
    });
  }

  void _handleSolve(String name) {
    setState(() {
      //FIXME: 先检查其他项填值没有
      double sum = 0.0;
      for (var i = 0; i < _terms.length; i++) {
        if (_terms.values.elementAt(i).name != name) {
          sum = sum + _terms.values.elementAt(i).value;
        }
      }
      _terms[name]!.value = -sum / _terms[name]!.weight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          for (var i = 0; i < _terms.length; i++)
            TermWidget(
              name: _terms.values.elementAt(i).name,
              value: _terms.values.elementAt(i).value,
              onSolve: _handleSolve,
              onSetValue: _handleSetValue,
            ),
        ],
      ),
    );
  }
}

class TermWidget extends StatelessWidget {
  const TermWidget({
    required this.name,
    required this.value,
    required this.onSetValue,
    required this.onSolve,
    super.key,
  });

  final String name;
  final double value;
  final Function(String, double) onSetValue;
  final Function(String) onSolve;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '请输入$name',
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                onSetValue(name, double.parse(value));
              }
            },
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () {
              onSolve(name);
            },
            child: const Text('求解'),
          ),
        ),
        Expanded(
          child: Text(value.toString()),
        ),
      ],
    );
  }
}
