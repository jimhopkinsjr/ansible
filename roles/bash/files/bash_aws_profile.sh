#!/use/bin/env bash

case "${TERM_PROGRAM}" in
    IDEA-C|PyCharm-C)
        case "${PWD}" in
            "${HOME}/puellmann.net")
                REPO_DIR="${PWD}"
                AWS_PROFILE="personal.jpuellma"
                export AWS_PROFILE
                ;;
        esac
        ;;
    iTerm.app)
        case "${ITERM_PROFILE}" in
            DEs)
                AWS_PROFILE="asynchrony.des.james.puellmann" && export AWS_PROFILE ;;
            JMFS*)
                JAVA_HOME=$(/usr/libexec/java_home -v 11 )&& export JAVA_HOME
                # AWS_PROFILE="jmfs.jpuellmann" && export AWS_PROFILE
                AWS_PROFILE="501925964695_heimdall-admin" && export AWS_PROFILE
                ;;
            Personal)
                AWS_PROFILE="personal.jpuellma" && export AWS_PROFILE ;;
            puellmann.net)
                REPO_DIR="${HOME}/puellmann.net"
                AWS_PROFILE="personal.jpuellma"
                export AWS_PROFILE
                cd "${REPO_DIR}" || return
                [[ -s "./venv/bin/activate" ]] && source "./venv/bin/activate"
                ;;
            SCE\ EBC)
                AWS_PROFILE="366238733069_FullAdmin_Marketplace" && export AWS_PROFILE ;;
            TSYS)
                AWS_PROFILE="tsys" && export AWS_PROFILE ;;
            WWT)
                AWS_PROFILE="wwt.jpuellma" && export AWS_PROFILE ;;
            *)
                AWS_PROFILE="none" && export AWS_PROFILE
                case "${TERM_PROGRAM}" in
                    vscode)
                        AWS_PROFILE="366238733069_FullAdmin_Marketplace" && export AWS_PROFILE ;;
                    *)
                        AWS_PROFILE="none" ;;
                esac
                ;;
        esac  # end case "${ITERM_PROFILE}
        ;;
    vscode)
        case "${VSWORKSPACE}" in
            bender)
                AWS_PROFILE="asynchrony.des.james.puellmann" && export AWS_PROFILE ;;
            sce)
                AWS_PROFILE="366238733069_FullAdmin_Marketplace" && export AWS_PROFILE ;;
            tf-aws-cp)
                AWS_PROFILE="asynchrony.des.james.puellmann" && export AWS_PROFILE ;;
            *)
                AWS_PROFILE="none" ;;
        esac  # end case "${VSWORKSPACE}"
        ;;
    *)
        AWS_PROFILE="none" ;;
esac  # end case "${TERM_PROGRAM}"
