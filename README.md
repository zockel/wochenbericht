# Wochenbericht LaTeX-Template
LaTeX Vorlage zum Erstellen von Wochenberichten inklusive Hilfsskript.


## Abhängigkeiten
Folgende Programme werden zum Ausführen des Helferskripts benötigt:

- [dialog](https://man.archlinux.org/man/dialog.1.en)
- [pdflatex](https://wiki.archlinux.org/title/TeX_Live)
- [vipe](https://man.archlinux.org/man/vipe.1)


## Anwendung
Das Helferskript kann durch folgenden Befehl aufgerufen werden:

```
cd /Pfad/zum/Skript
chmod +x wochenbericht.sh
./wochenbericht.sh
```

Nach der Abfrage der grundlegenden Daten öffnet sich der Standardeditor um
die Inhalte der einzelnen Rubriken einzutragen.

(`vipe` nutzt dazu die `$EDITOR` Umgebungsvariable)


## Anpassung
Der Pfad zur Template Datei und zum Ausgabeverzeichnis können direkt im Skript
mit den Variablen `tex_dir` und `out_dir` angepasst werden.
Wenn eine andere TeX-Distro genutzt werden soll kann die `tex_cmd` Funktion
angespasst werden.
