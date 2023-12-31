# Hydrate skeleton with example specifications ---------------------------------
library(Hydra)
specifications <- loadSpecifications("extras/ExamplePleSpecs.json")
packageFolder <- "d:/temp/hydraPleOutput"
unlink(packageFolder, recursive = TRUE)
hydrate(specifications = specifications, outputFolder = packageFolder)

# Build the hydrated package and put it into the renv
# cellar: https://rstudio.github.io/renv/articles/cellar.html
renvCellarPath <- file.path(packageFolder, "renv/cellar")
if (!dir.exists(renvCellarPath)) {
  dir.create(renvCellarPath, recursive = TRUE)
}
packageZipFile <- devtools::build(pkg = packageFolder,
                                  path = renvCellarPath)


renv::load(packageFolder)
renv::restore(project = packageFolder, prompt = FALSE)
renv::install(c("remotes", "Eunomia"))
renv::install(project = packageFolder,
              packages = packageZipFile)


# Run the package ------------------------------------------------------------
script <- "
        library(pleTestPackage)
        options(andromedaTempFolder = 'd:/andromedaTemp')

        outputFolder <- 'd:/temp/hydraPleResults'
        unlink(outputFolder, recursive = TRUE)
        maxCores <- 1
        connectionDetails <- Eunomia::getEunomiaConnectionDetails()
        cdmDatabaseSchema <- 'main'
        cohortDatabaseSchema <- 'main'
        cohortTable <- 'cd_skeleton'
        databaseId <- 'Eunomia'
        databaseName <- 'Eunomia'
        databaseDescription <- 'Eunomia'

        execute(connectionDetails = connectionDetails,
                cdmDatabaseSchema = cdmDatabaseSchema,
                cohortDatabaseSchema = cohortDatabaseSchema,
                cohortTable = cohortTable,
                outputFolder = outputFolder,
                databaseId = databaseId,
                databaseName = databaseName,
                databaseDescription = databaseDescription,
                createCohorts = TRUE,
                synthesizePositiveControls = FALSE,
                runAnalyses = TRUE,
                packageResults = TRUE,
                maxCores = maxCores)
"
script <- gsub("packageFolder", sprintf("\"%s\"", packageFolder), script)
tempScriptFile <- file.path(packageFolder, basename(tempfile(fileext = ".R")))
fileConn<-file(tempScriptFile)
writeLines(script, fileConn)
close(fileConn)

renv::run(script = tempScriptFile,
          name = "Study package",
          project = packageFolder)


# # Not part of study execution: View results in Shiny app -----------------------
# renv::load(packageFolder)
# 
# outputFolder <- "s:/pleTestPackage"
# resultsZipFile <- file.path(outputFolder, "export", paste0("Results_Synpuf.zip"))
# dataFolder <- file.path(outputFolder, "shinyData")
# prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
# launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)
