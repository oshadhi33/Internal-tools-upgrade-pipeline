pipeline {

    agent any

    triggers {
        cron('H H 1 * *')
    }

    environment {
        SLACK_WEBHOOK = credentials('slack-webhook')
    }

    stages {

        stage('Load Environment Variables') {
            steps {
                script {
                    // Load environment variables from .env file if it exists
                    sh '''
                        if [ -f .env ]; then
                            echo "Loading environment variables from .env file"
                            export $(cat .env | grep -v '^#' | xargs)
                        else
                            echo "No .env file found, using existing environment variables"
                        fi
                    '''
                }
            }
        }

        stage('Setup Logging') {
            steps {
                script {
                    // Create logs directory
                    sh 'mkdir -p logs'
                    // Source logger functions
                    sh '''
                        . scripts/logger.sh
                        log_info "Starting internal tools upgrade pipeline"
                    '''
                }
            }
        }

        stage('Upgrade Internal Tools') {

            steps {

                script {

                    def apps = readYaml file: 'inventory/apps.yml'
                    def logFile = "logs/upgrade_${env.BUILD_NUMBER}.log"

                    sh ". scripts/logger.sh && log_info 'Loaded configuration for ${apps.apps.size()} apps'"

                    for (app in apps.apps) {

                        echo "===================================="
                        echo "Starting upgrade for ${app.name}"
                        echo "===================================="

                        sh ". scripts/logger.sh && log_info 'Starting upgrade for ${app.name}'"

                        try {

                            sshagent(['hetzner_tools_prod']) {

                                sh """
                                . scripts/logger.sh && log_info "Running Ansible playbook for ${app.name}" && \
                                . .env && \
                                ansible-playbook playbooks/main.yml \
                                  -i inventory/hosts.ini \
                                  --limit ${app.host_group} \
                                  -e target_app=${app.name} \
                                  -e log_file=${logFile} \
                                  -e "AWS_ACCESS_KEY_ID=\${AWS_ACCESS_KEY_ID}" \
                                  -e "AWS_SECRET_ACCESS_KEY=\${AWS_SECRET_ACCESS_KEY}" \
                                  -e "AWS_DEFAULT_REGION=\${AWS_DEFAULT_REGION}" \
                                  -e "APPSMITH_VOLUME_ID_1=\${APPSMITH_VOLUME_ID_1}" \
                                  -e "APPSMITH_VOLUME_ID_2=\${APPSMITH_VOLUME_ID_2}" \
                                  2>&1 | tee -a ${logFile}
                                """
                            }

                            sh ". scripts/logger.sh && log_info '${app.name} upgraded successfully'"
                            echo "${app.name} upgraded successfully"

                            sh """
                            ./scripts/slack_notify.sh \
                            "${app.name}" \
                            "SUCCESS" \
                            "${SLACK_WEBHOOK}"
                            """

                        } catch (Exception e) {

                            sh ". scripts/logger.sh && log_error '${app.name} upgrade failed: ${e.message}'"
                            echo "${app.name} failed"

                            sh """
                            ./scripts/slack_notify.sh \
                            "${app.name}" \
                            "FAILED" \
                            "${SLACK_WEBHOOK}"
                            """

                            continue
                        }
                    }

                    sh ". scripts/logger.sh && log_info 'All upgrades completed'"
                }
            }
        }
    }

    post {

        always {
            sh '. scripts/logger.sh && log_info "Pipeline finished"'
            archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
        }

        success {
            sh '. scripts/logger.sh && log_info "Pipeline completed successfully"'
        }

        failure {
            sh '. scripts/logger.sh && log_error "Pipeline failed"'
        }
    }
}
