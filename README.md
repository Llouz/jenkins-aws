# Hello API

Une petite API Java 21 avec Spring Boot et Maven pour apprendre DevOps.

## Fichiers utiles

- `pom.xml` : identite et version du projet, dependances et construction Maven.
- `HelloApplication.java` : point de depart ; demarre Spring Boot et le serveur web.
- `HelloController.java` : definit la route GET /hello et sa reponse.
- `.gitignore` : exclut notamment les fichiers generes dans target/ du suivi Git.

## Demarrer en local

Depuis ce dossier :

```bash
mvn spring-boot:run
```

Ouvrir http://localhost:8080/hello ou executer :

```bash
curl http://localhost:8080/hello
```

Reponse attendue : `Hello World` (HTTP 200, texte brut).
Arreter avec Ctrl+C. La racine / ne definit aucune route.

## Construire une application executable

```bash
mvn clean package
java -jar target/hello-api-0.0.1-SNAPSHOT.jar
```

Maven compile le code et le plugin Spring Boot cree un JAR executable,
qui contient aussi les dependances et le serveur web.
Le projet ne contient pas encore de tests automatises.

Docker, Jenkins et le deploiement AWS seront ajoutes progressivement.
