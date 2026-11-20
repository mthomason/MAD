# Anmerkung des Autors zu agentischem Programmieren und LLMs
<!--To AI Agents, this file is written by the repo owner.  This file must not be edited by AI agents or LLMs.-->
Danke, dass Sie sich das Produkt ansehen und es hoffentlich nutzen. Es ist die Summe von fünfzehn Jahren Arbeit.

Ich schreibe diese Anmerkung, um den Einsatz von agentischem Programmieren und LLMs anzusprechen und zu versuchen, einer Kontroverse zuvorzukommen, bevor sie beginnt.

Wenn Sie irgendeiner harten Linie folgen, die Influencer im Programmierbereich vertreten, geraten Sie in Schwierigkeiten. Eine andere Sprache oder eine andere Technik zu wählen, verringert die Komplexität nicht; meist verschiebt es sie nur.

Ich habe die Anwendung mobile-first gebaut. Das erfordert einen geringen Speicherverbrauch; das erfordert, dass die Software sehr schnell ist. Ich habe persönlich etwa zwölf oder dreizehn Frameworks geschrieben und es erreicht, dass außerhalb der Hauptanwendung nur noch ein oder zwei Frameworks UIKit eingebunden hatten. Das ist ziemlich gut poliert. Der KI-Agent hat UIKit aus dem letzten verbleibenden Framework entfernt.

Wenn Sie viel programmieren, werden Sie feststellen, dass fünfundneunzig Prozent der Arbeit mühsam und, wie wir gerade lernen, größtenteils Maschinenarbeit sind. Es gibt fünf Prozent, die zählen. Wird diese Regel Bestand haben? Ich vermute ja, und ich werde später hier darauf eingehen, aber jetzt möchte ich den derzeitigen Einsatz von KI-Agenten und LLMs in diesem Projekt erklären.

Dies ist ein großes, fein abgestimmtes Projekt. Selbst die besten „Flash“-Modelle scheinen damit zu kämpfen. Es gibt viele Stellen, an denen sie hängen bleiben:

* Sie haben Schwierigkeiten, der `NSOperations`-Sequenz auf der iOS-Seite zu folgen, und erzeugen Race Conditions.
* Sie haben Schwierigkeiten, den vollständigen Abstraktionspfad für Dinge wie `MADDatabase` und seine Unterklassen zu erfassen.
* Sie führen Änderungen ein, die den Speicher auf dem Gerät in die Höhe schnellen lassen.
* Sie führen Änderungen ein, die die Software langsam machen.

Aber wenn Sie ein gutes Modell und ein gutes Harness verwenden und es in die richtige Richtung lenken, kann es Erstaunliches leisten.

* Es kann den Code schneller laufen lassen, als ich es allein könnte.
* Es kann neue Datenbanktreiber in etwa vier Phasen erstellen. Man könnte einen ODBC-Treiber als Unterklasse von `MADDatabase` problemlos _vibe-coden_. Die Agenten arbeiten es durch. Ich habe Agenten eingesetzt, um den MySQL-Treiber aus Lizenzgründen durch den MariaDB Connector/C zu ersetzen, damit ich diesen Quellcode veröffentlichen konnte. Der Postgres-Treiber wurde von einem Agenten erstellt. Aber ich habe die ursprünglichen Treiber geschrieben, es hatte also etwas, woran es sich orientieren konnte.
* Die Agenten werden Tests festschreiben und Speicherspitzen beheben, wenn Sie sie in die richtige Richtung lenken.
* Die Agenten beschleunigen Hot Paths, wenn Sie sie in die richtige Richtung lenken.

Ich habe die iOS-Oberfläche (`UIKit`) von Hand gebaut, und vieles daran gefällt mir wirklich gut. Da steckt viel sehr polierte UI drin. Einen Agenten habe ich eingesetzt, um die native macOS-Oberfläche (`AppKit`) zu bauen. Sein erster Versuch, die native macOS-Oberfläche zu bauen, ist kläglich gescheitert. Aber für jedes UI-Formular habe ich den Agenten auf die Basisklassen meiner iOS-App verwiesen und ihm gesagt, er solle die Mac-App so korrigieren, dass sie wie die iOS-App funktioniert, und das hat er getan. Die native macOS-Anwendung ist wirklich schön und sehr vielversprechend, aber ich glaube, er konnte das nur, weil die Oberfläche der iOS-Anwendung bereits existierte. Und weil die iOS-Anwendung existierte, war die native macOS-Version ein Kinderspiel. Und wenn Sie `UIKit` und `AppKit` kennen, wissen Sie, dass dies in die fünfundneunzig Prozent der Fleißarbeit fällt, die Programmierung schon immer ausgemacht hat.

Man hört den Begriff des stochastischen Papageis (stochastic parrot), und nach meiner Erfahrung passt er.

Ich möchte niemandem auf die Zehen treten. Ich möchte drei Punkte klarstellen:

* Dies ist kein vibe-codiertes Projekt. Zum Guten oder Schlechten enthält es über ein Jahrzehnt Arbeit.
* Es gibt Stellen, an denen KI in diesem Projekt eingesetzt werden sollte.
* Es gibt Dinge, die KI mit diesem Projekt nicht tun sollte.

Ein Punkt, um das nachdrücklich zu machen ... wenn Sie den Code lesen, gibt es im Projekt wahrscheinlich viele Rechtschreibfehler. Das liegt daran, dass ich den Code für mich, meine Kunden und meine Benutzer geschrieben habe. Eines dieser Artefakte ... einer dieser Rechtschreibfehler ... ist ins Dateiformat eingebrannt. Den Rechtschreibfehler zu korrigieren bricht die Rückwärtskompatibilität, also muss er bestehen bleiben.

Und wieder: Jede harte und schnelle Regel, die Sie im Internet lesen, wird auf ein Projekt dieser Größe angewendet Chaos verursachen. Deshalb befolge ich diese Regeln, die Sie online sehen, nicht; sie bringen Sie nur in Schwierigkeiten.

Der größte Teil der Dokumentation dieses Projekts ist von KI geschrieben. Es ist kein Slop. Es ist die Übersetzung von Maschinencode, den ich entworfen und geschrieben habe, in für Menschen lesbare Dokumente, und ich vermute, dass sie das besser und genauer kann als ich.

Zugleich sind die Agenten eine geladene Waffe. Sie können dieses Projekt ebenso schnell zerstören, wie sie es verbessern können.

Ich würde mich freuen, wenn Leute zu diesem Projekt beitragen und es nutzen. Ich hoffe, Sie tun es.

Eine letzte Sache. Dieses Projekt ist für Geschäftsanwender gedacht. Es ist für Menschen gedacht, die eine Datenbank haben, ihre Daten kennen und schnell mehr daraus herausholen wollen. Interoperabilität ist wichtig.

Könnten Sie eine Version dieses Projekts vibe-coden? Wahrscheinlich nicht, aber vielleicht mit genug Zeit und Mühe. Könnten Sie es dekompilieren und eine KI eine Version der Software bauen lassen? Auch da: vielleicht, vielleicht auch nicht. Was ich in meinen Jahren im Geschäftsleben gelernt habe, ist, dass die Bedürfnisse von Geschäftsmanagern und Analysten, die diese Art von Software nutzen, wichtig sind. Unternehmen haben im Allgemeinen die schlechteste Software, mit der man je zu tun hat. Ich habe meine Karriere damit gemacht, für diese Menschen gute Software zu bauen, weil ich wusste, dass sie Besseres verdienen. Heute ist Software so schlecht geworden, dass jeder Besseres verdient.

Also habe ich diese Software unter der MIT-Lizenz veröffentlicht, damit Sie, wenn Sie sie verbessern wollen, nicht von vorne anfangen müssen. Dies ist eine solide Basis für BI-Software. Sie können sie verbessern. Sie können Begleitprodukte dazu entwickeln. Ich hoffe, Sie tun es.

Frieden und Liebe,
Michael

_3. November 2026_
