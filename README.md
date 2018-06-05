# MGPL-XText
This project specifies the grammar of the Mini-Game-Programming-Language (MGPL) using XText to generate a compiler, validator and code generator for the MGPL. It can be used to create a new Eclipse instance to create, edit and validate MGPL-projects and generates Java code if the MGPL-project is a valid MGPL.

## Editor
The XText framework generates a simple editor which validates your MGPL code immediately during editing. If your code is valid it is compiled to Java. The main method(s) are written to the *program-name*UI class. It uses the JavaFX framework for the GUI.

## Importing into Eclipse
TO import this project into Eclipse just check this git repository out, import it via the option *Existing Projects into Workspace* and run after the successful import the *Generate XText artifacts* command on the MGPL.xtext file in the *org.xtext.vuc.mgpl* package of the source folder of the *org.xtext.vuc.mgpl* project to generate all neccessary files and settings.

## License
This project is published under the terms of the [Apache-2.0 license](LICENSE).
