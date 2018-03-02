#!/usr/bin/env groovy

library("govuk")

repoName = JOB_NAME.split('/')[0]

node {

  try {
    stage("Checkout") {
      govuk.checkoutFromGitHubWithSSH(repoName, "gds-operations")
    }

    stage("Clean up workspace") {
      govuk.cleanupGit()
    }

    stage("bundle install") {
      govuk.setEnvar("RBENV_VERSION", "2.2.2")
      govuk.bundleGem()
    }

    stage("Run tests") {
      govuk.runTests()
    }

    if (env.BRANCH_NAME == "master") {
      stage("Publish gem") {
        govuk.publishGem(repoName, env.BRANCH_NAME)
      }
    }
  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}

