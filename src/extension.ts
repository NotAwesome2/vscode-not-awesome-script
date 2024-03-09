// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from "vscode";

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
  const wordRegex = new RegExp(/(#[a-zA-Z0-9_\-\.]+)/g);
  const definitionRegex = new RegExp(/^(\s*)(#[a-zA-Z0-9_\-\.]+)/);

  let disposable = vscode.languages.registerDefinitionProvider(
    "classicube-script",
    {
      provideDefinition(document, position, token) {
        const locations: vscode.LocationLink[] = [];

        const wordRange = document.getWordRangeAtPosition(position, wordRegex);
        if (wordRange) {
          const word = document.getText(wordRange);

          for (let line = 0; line < document.lineCount; line++) {
            const textLine = document.lineAt(line);

            const match = textLine.text.match(definitionRegex);
            if (match?.[2] === word) {
              const start = match[1].length ?? 0;
              const end = start + match[2].length;

              locations.push({
                // full line match
                targetRange: textLine.range.with({
                  start: textLine.range.start.with({
                    // without beginning whitespace
                    character: start,
                  }),
                }),
                targetUri: document.uri,
                originSelectionRange: wordRange,
                // only name match
                targetSelectionRange: new vscode.Range(
                  textLine.range.start.with({
                    character: start,
                  }),
                  textLine.range.end.with({
                    character: end,
                  })
                ),
              });
            }
          }
        }

        return locations;
      },
    }
  );
  context.subscriptions.push(disposable);

  disposable = vscode.languages.registerReferenceProvider("classicube-script", {
    provideReferences(document, position, context, token) {
      const locations: vscode.Location[] = [];

      const wordRange = document.getWordRangeAtPosition(position, wordRegex);
      if (wordRange) {
        const word = document.getText(wordRange);

        for (let line = 0; line < document.lineCount; line++) {
          const textLine = document.lineAt(line);
          for (const match of textLine.text.matchAll(wordRegex)) {
            if (match?.[1] === word) {
              const start = match.index ?? 0;
              const end = start + match[1].length;

              locations.push(
                new vscode.Location(
                  document.uri,
                  new vscode.Range(
                    textLine.range.start.with({
                      character: start,
                    }),
                    textLine.range.end.with({
                      character: end,
                    })
                  )
                )
              );
            }
          }
        }
      }

      return locations;
    },
  });
  context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
export function deactivate() {}
