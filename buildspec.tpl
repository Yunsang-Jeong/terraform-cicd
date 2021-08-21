version: 0.2

env:
  variables:
    ##################################
    # Pipeline에 대한 설정 값입니다.
    CONFIG_FILE: ".config" 
    ##################################

    ##################################
    # terraform init 과정에서 module을 갱신합니다.
    FORCE_INIT: "false"
    ##################################

    ##################################
    # Terraform 실행에 대한 내용입니다.
    # TF_LOG: "TRACE"
    TF_CLI_ARGS: "-no-color"
    TF_PLUGIN_CACHE_DIR: "/usr/lib/terraform-cache/"
    ##################################


phases:
  pre_build:
    commands:
      ##################################
      # CONFIG 파일로 부터 값을 읽어와 환경변수에 추가합니다.
      - export $(xargs < $CONFIG_FILE)
      # [필수] BUILDACTION
      ##################################
      
      ##################################
      # AWS Codecommit으로 부터 Module을 다운로드 받을 때, AWS CLI 권한을 사용하도록 설정합니다.
      # - git config --global credential.helper "!aws codecommit credential-helper $@"
      # - git config --global credential.UseHttpPath true
      ##################################

      ##################################
      # Terraform init을 수행합니다.
      - terraform init -input=false -upgrade=$FORCE_INIT -backend-config=backend.tfvars
      ##################################

  build:
    commands:
      ##################################
      # Terraform Workspace를 생성 및 선택합니다.
      - terraform workspace new $WORKSPACE && terraform workspace select $WORKSPACE || terraform workspace select $WORKSPACE
      ##################################

      ##################################
      # 현재 실행중인 Build의 단계에 따라 Plan을 생성하거나 인프라에 적용합니다.
      - |
        if [ "$BUILDSTEP" == "planner" ]; then
          if [ "$BUILDACTION" == "apply" ]; then
            terraform plan -var-file=provider.tfvars -out=$CODEBUILD_BUILD_ID.plan
          elif [ "$BUILDACTION" == "destroy" ]; then
            terraform plan -var-file=provider.tfvars -out=$CODEBUILD_BUILD_ID.plan -destroy
          fi
        elif [ "$BUILDSTEP" == "runner" ]; then
          terraform apply -auto-approve $(ls $CODEBUILD_SRC_DIR_TerraformPlan/*.plan)
        fi
      ##################################

artifacts:
  name: $TIMESTAMP_$CODEBUILD_BUILD_ID
  files:
    - "$CODEBUILD_BUILD_ID.plan"

cache:
  paths:
    - ".terraform/plugins/**/*"
    - ".terraform/modules/**/*"