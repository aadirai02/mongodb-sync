# MongoDB Production → Staging Sync System

This repository provides a **fully automated, repeatable, and safe workflow** to sync **anonymized production MongoDB data** into a **staging MongoDB instance** running on an Amazon EKS cluster.

It handles:

- Exporting **anonymized** data from Production  
- Uploading to **S3**  
- Restoring on **Staging**  

---

## 🚀 Prerequisites

Ensure the following tools are installed and configured:

- **AWS CLI** (configured with sufficient permissions)  
- **Terraform v1.5+**  
- **kubectl v1.33+**  
- **make**  
- **git**
- **docker** 
- **ECR Repository** (Simple docker image to install awscli in mongo:7.0 image)

---

## 📦 Clone the Repository

```
git clone https://github.com/aadirai02/mongodb-sync.git
cd mongodb-sync
```

---

## ⚡ Quick Start (Fully Automated Sync)

Run one command to provision infrastructure, sync prod data, and restore into staging:

```
make -f Makefile.final all
```

This performs the complete pipeline end-to-end.

---

## 🔧 Step-by-Step Execution (Manual Sequence)

If you want to execute each stage manually, follow the steps below.

### 1️⃣ Provision EKS Clusters (Prod + Staging)

```
cd terraform/modules/eks && terraform init
cd ../../../makefiles
make -f makefiles/Makefile.infra all
```

### 2️⃣ Setup IRSA Roles (Sync + Restore)

```
bash scripts/setup-irsa-staging-restore.sh
bash scripts/setup-irsa-sync.sh
```

### 3️⃣ Sync Production Data (Anonymized Export → S3)

```
make -f makefiles/Makefile.sync sync-prod
```

### 4️⃣ Restore Data into Staging

```
make -f makefiles/Makefile.restore all
```

---

### 5️⃣ To destroy everything

```
make -f makefiles/Makefile.infra destroy
```

---

## 📘 Additional Resources

For pre-checks, verification, and rollback procedures, refer to:

`runbook.md`

For architecture details, see:

`Design.png`

---

## ⏱ Expected Duration

Approximate total execution time (excluding EKS provisioning):

- **Production sync:** ~5 minutes  
- **Staging restore:** 2–5 minutes  
- **Total:** ~10 minutes (depending on data size)
```

🚨 Important notice – Replace the ECR URL with your own ECR repository URL 🚨
