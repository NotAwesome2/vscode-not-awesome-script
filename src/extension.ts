// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from "vscode";

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
  const variableRegex = new RegExp(/([a-zA-Z0-9_\-\.]+)/g);
  const variableAssignRegex = new RegExp(
    /^(\s*)((?:set|setsplit|setadd|setblockid|setdirvector|setdiv|setmod|setmul|setrandrange|setrandrangedecimal|setround|setrounddown|setroundup|setsub)\s+)([a-zA-Z0-9_\-\.]+)/
  );

  const functionLabelRegex = new RegExp(/(#[a-zA-Z0-9_\-\.]+)/g);
  const functionDefinitionRegex = new RegExp(/^(\s*)(#[a-zA-Z0-9_\-\.]+)/);

  let disposable = vscode.languages.registerDefinitionProvider(
    "classicube-script",
    {
      provideDefinition(document, position, token) {
        const locations: vscode.LocationLink[] = [];

        const functionWordRange = document.getWordRangeAtPosition(
          position,
          functionLabelRegex
        );
        if (functionWordRange) {
          const word = document.getText(functionWordRange);

          for (let line = 0; line < document.lineCount; line++) {
            const textLine = document.lineAt(line);

            const match = textLine.text.match(functionDefinitionRegex);
            if (match?.[2] === word) {
              const whitespaceEnd = match[1].length ?? 0;
              const codeEnd = whitespaceEnd + match[2].length;

              locations.push({
                // full line match
                targetRange: textLine.range.with({
                  start: textLine.range.start.with({
                    // without beginning whitespace
                    character: whitespaceEnd,
                  }),
                }),
                targetUri: document.uri,
                originSelectionRange: functionWordRange,
                // only name match
                targetSelectionRange: new vscode.Range(
                  textLine.range.start.with({
                    character: whitespaceEnd,
                  }),
                  textLine.range.end.with({
                    character: codeEnd,
                  })
                ),
              });
            }
          }
        } else {
          const variableWordRange = document.getWordRangeAtPosition(
            position,
            variableRegex
          );
          if (variableWordRange) {
            const word = document.getText(variableWordRange);

            for (let line = 0; line < document.lineCount; line++) {
              const textLine = document.lineAt(line);

              const match = textLine.text.match(variableAssignRegex);
              if (match?.[3] === word) {
                const whitespaceEnd = match[1].length ?? 0;
                const codeStart = whitespaceEnd + (match[2].length ?? 0);
                const codeEnd = codeStart + match[3].length;

                locations.push({
                  // full line match
                  targetRange: textLine.range.with({
                    start: textLine.range.start.with({
                      // without beginning whitespace
                      character: whitespaceEnd,
                    }),
                  }),
                  targetUri: document.uri,
                  originSelectionRange: variableWordRange,
                  // only name match
                  targetSelectionRange: new vscode.Range(
                    textLine.range.start.with({
                      character: codeStart,
                    }),
                    textLine.range.end.with({
                      character: codeEnd,
                    })
                  ),
                });
              }
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

      const functionWordRange = document.getWordRangeAtPosition(
        position,
        functionLabelRegex
      );
      if (functionWordRange) {
        const word = document.getText(functionWordRange);

        for (let line = 0; line < document.lineCount; line++) {
          const textLine = document.lineAt(line);
          for (const match of textLine.text.matchAll(functionLabelRegex)) {
            if (match?.[1] === word) {
              const codeStart = match.index ?? 0;
              const codeEnd = codeStart + match[1].length;

              locations.push(
                new vscode.Location(
                  document.uri,
                  new vscode.Range(
                    textLine.range.start.with({
                      character: codeStart,
                    }),
                    textLine.range.end.with({
                      character: codeEnd,
                    })
                  )
                )
              );
            }
          }
        }
      } else {
        const variableWordRange = document.getWordRangeAtPosition(
          position,
          variableRegex
        );
        if (variableWordRange) {
          const word = document.getText(variableWordRange);

          for (let line = 0; line < document.lineCount; line++) {
            const textLine = document.lineAt(line);

            for (const match of textLine.text.matchAll(variableRegex)) {
              if (match?.[1] === word) {
                const codeStart = match.index ?? 0;
                const codeEnd = codeStart + match[1].length;

                locations.push(
                  new vscode.Location(
                    document.uri,
                    new vscode.Range(
                      textLine.range.start.with({
                        character: codeStart,
                      }),
                      textLine.range.end.with({
                        character: codeEnd,
                      })
                    )
                  )
                );
              }
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
