// ==========================================
// 1. CONFIGURATION & CORE ELEMENTS
// ==========================================
const API_BASE_URL = "https://8nwb2d8l5k.execute-api.us-east-1.amazonaws.com/execute";

const workspaceForm = document.getElementById('workspace-form');
const requestDropdown = document.getElementById('request-type');
const innerWsTypeDropdown = document.getElementById('new-workspace-type');
const errorBanner = document.getElementById('error-message-banner');
const fetchBtn = document.getElementById('fetch-details-btn');
const confirmSubmitBtn = document.getElementById('confirmSubmitBtn');
const reviewModal = document.getElementById('review-modal');
const reviewContainer = document.getElementById('review-data-container');

let finalValidatedData = null; // Buffer for Modal review

// ==========================================
// 2. DYNAMIC INPUT HELPERS
// ==========================================
function addNewInput(containerId, category, value = "") {
    const container = document.getElementById(containerId);
    const div = document.createElement('div');
    div.className = 'group-item';
    div.innerHTML = `
    <input type="text" value="${value}" placeholder="Enter ${category} group" class="${category}-group-input">
    <button type="button" class="delete-btn" onclick="this.parentElement.remove()">×</button>
    `;
    container.appendChild(div);
}

function gatherListValues(className) {
    return Array.from(document.querySelectorAll('.' + className))
    .map(input => input.value.trim())
    .filter(val => val !== "");
}

function clearDynamicLists() {
    ['apply-list', 'plan-list', 'read-list'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.innerHTML = "";
    });
}

// ==========================================
// 3. FETCH WORKSPACE DETAILS (GET)
// ==========================================
if (fetchBtn) {
    fetchBtn.addEventListener('click', async function() {
        const wsName = document.getElementById('group-ws-name').value.trim();
        if (!wsName) return showError("Please enter a workspace name first.");

        fetchBtn.innerText = "🔍 Connecting...";
        fetchBtn.disabled = true;
        clearDynamicLists();

        try {
            const response = await fetch(`${API_BASE_URL}/get-workspace?workspace=${wsName}`);
            if (!response.ok) throw new Error("Workspace not found.");
            const data = await response.json();

            data.apply.forEach(val => addNewInput('apply-list', 'apply', val));
            data.plan.forEach(val => addNewInput('plan-list', 'plan', val));
            data.read.forEach(val => addNewInput('read-list', 'read', val));

            const applyAddBtn = document.querySelector('[onclick*="apply-list"]');
            if (data.type === 'tep') {
                if (applyAddBtn) applyAddBtn.style.display = 'none';
                document.getElementById('apply-list').innerHTML = "<div style='color:orange'>Apply access restricted for TEP.</div>";
            } else if (applyAddBtn) {
                applyAddBtn.style.display = 'inline-block';
            }
        } catch (err) {
            showStatus("Fetch Failed: " + err.message, "error");
        } finally {
            fetchBtn.innerText = "Fetch Details";
            fetchBtn.disabled = false;
        }
    });
}

// ==========================================
// 4. NAVIGATION & UI LOGIC
// ==========================================
requestDropdown.addEventListener('change', function() {
    closeModal(); // Close review if type changes
    document.querySelectorAll('.extra-fields').forEach(section => {
        section.style.display = "none";
        section.querySelectorAll('input, select').forEach(input => input.value = "");
    });
    const sectionToShow = document.getElementById('fields-' + this.value);
    if (sectionToShow) sectionToShow.style.display = "block";
});

if (innerWsTypeDropdown) {
    innerWsTypeDropdown.addEventListener('change', function() {
        document.querySelectorAll('.sub-extra-fields').forEach(sub => sub.style.display = 'none');
        const subToShow = document.getElementById('subfields-' + this.value);
        if (subToShow) subToShow.style.display = 'block';
    });
}

function closeModal() {
    reviewModal.style.display = "";
    reviewContainer.innerHTML = "";
}

// ==========================================
// 5. DATA GATHERING & VALIDATION
// ==========================================
function gatherFormData() {
    errorBanner.style.display = 'none';
    const validationErrors = [];
    const infoMessages = [];
    let formData = { requestType: requestDropdown.value };

    if (formData.requestType === "default") {
        showStatus("Please select a Request Type.", "error");
        return null;
    }

    const activeSection = document.querySelector('.extra-fields[style*="display: block"]');
    if (activeSection) {
        activeSection.querySelectorAll('input, select').forEach(input => {
            const key = input.id || input.name;
            if (key && input.value.trim() !== "" && input.value !== "default") {
                formData[key] = input.value.trim();
            }
        });
    }

    // --- 1. System Number, AWS ID Validation ---
    const systemNumRegex = /^([a-z]\d{3,4}|\d{4,5})$/;
    const sysNumValue = formData['new-system-num'] || formData['current-system-num'] || formData['system-num'];

    if (sysNumValue && !systemNumRegex.test(sysNumValue)) {
        validationErrors.push("System Number must be 4-5 digits or a lowercase letter followed by 3-4 digits.");
    }

    const awsRegex = /^\d{12}$/;
    const awsFields = ['aws-account-num', 'current-aws-num', 'new-aws-num', 'convert-aws-num'];

    awsFields.forEach(field => {
        if (formData[field] && !awsRegex.test(formData[field])) {
            // Mapping technical ID to a readable name for the error message
            const friendlyName = field.replace(/-/g, ' ').toUpperCase();
            validationErrors.push(`${friendlyName} must be exactly 12 digits.`);
        }
    });

    // --- 2. Mandatory Workspace Name (Global Fix) ---
    // Added 'convert-ws-name' and 'aws-ws-name' to ensure these sections pass validation
    const wsName = formData['new-ws-name'] ||
                    formData['group-ws-name'] ||
                    formData['version-ws-name'] ||
                    formData['misc-ws-name'] ||
                    formData['convert-ws-name'] ||
                    formData['aws-change-ws-name'];

                if (!wsName) {
                    validationErrors.push("Workspace Name is mandatory for all requests.");
                }

                // --- 3. Request-Specific Logic ---

                // A. OKTA GROUP CHANGE: Must change at least one field
                if (formData.requestType === 'access-group-update') {
                    const apply = gatherListValues('apply-group-input');
                    const plan = gatherListValues('plan-group-input');
                    const read = gatherListValues('read-group-input');

                    if (apply.length === 0 && plan.length === 0 && read.length === 0) {
                        validationErrors.push("At least one group change is necessary for Okta updates.");
                    }
                    formData.applyGroups = apply;
                    formData.planGroups = plan;
                    formData.readGroups = read;
                }

                // B. MISC REQUEST: At least one change/detail is required
                if (formData.requestType === 'misc-request') {
                    // We filter out requestType and wsName to see if the user actually typed something in the other fields
                    const miscDataPoints = Object.keys(formData).filter(key =>
                    key !== 'requestType' && key !== 'misc-ws-name'
                    );
                    if (miscDataPoints.length === 0) {
                        validationErrors.push("For Misc requests, at least one change or detail must be provided.");
                    }
                }

                // C. WORKSPACE CREATION
                if (formData.requestType === 'new-workspace') {
                    if (!formData['lob']) validationErrors.push("LOB is mandatory.");

                    if (!formData['new-workspace-type'] || formData['new-workspace-type'] === "default") {
                        validationErrors.push("Workspace Type (VCS, TEP, etc.) is mandatory.");
                    }

                    // FIX: AWS Account is NOT mandatory if 'Non-AWS' is selected for TEP
                    const isNonAwsTep = (formData['new-workspace-type'] === 'tep' && formData['tep-category'] === 'non-aws');

                    if (!isNonAwsTep && !formData['aws-account-num']) {
                        validationErrors.push("AWS Account Number is mandatory.");
                    }

                    // VCS Specifics
                    if (formData['new-workspace-type'] === 'vcs') {
                        if (!formData['repo-url']) validationErrors.push("Repo URL is mandatory.");
                        if (!formData['branch']) validationErrors.push("Branch is mandatory.");
                        if (!formData['vcs-apply-group']) validationErrors.push("Apply Team is mandatory.");
                    }

                    // TEP Specifics
                    if (formData['new-workspace-type'] === 'tep') {
                        if (!formData['tep-plan-group']) validationErrors.push("Plan Group is mandatory for TEP.");
                    }
                }

                // D. NON-AWS & NON-VCS
                if (formData['workspace-category'] === 'non-aws-tep' && !formData['plan-group']) {
                    validationErrors.push("Plan is mandatory for Non-AWS TEP.");
                }
                if (formData['is-non-vcs'] === 'true' && !formData['apply-group']) {
                    validationErrors.push("Apply is mandatory for Non-VCS workspaces.");
                }

                // --- 4. Version Update Specifics (> 0.13.XX) ---
                if (formData.requestType === 'update-version') {
                    const version = formData['version-value'];
                    const versionRegex = /^(\d+)\.(\d+)\.(\d+)$/;
                    const match = version ? version.match(versionRegex) : null;

                    if (!match) {
                        validationErrors.push("Version must be in format xx.xx.xx");
                    } else {
                        const major = parseInt(match[1]);
                        const minor = parseInt(match[2]);
                        if (major === 0 && minor <= 13) {
                            validationErrors.push("Version value must be greater than 0.13.XX");
                        }
                    }
                }

                // E. NEW: CHANGE AWS ACCOUNT ID MANDATORY CHECK
                if (formData.requestType === 'change-aws-account') {
                    if (!formData['current-aws-num']) {
                        validationErrors.push("Current AWS Account ID is mandatory.");
                    }
                    if (!formData['new-aws-num']) {
                        validationErrors.push("New AWS Account ID is mandatory.");
                    }
                }

                // --- 5. Collapse Logic ---
                let a = formData.applyGroups || [formData['vcs-apply-group'] || formData['apply-group']].filter(Boolean);
                let p = formData.planGroups || [formData['vcs-plan-group'] || formData['tep-plan-group'] || formData['plan-group']].filter(Boolean);
                let r = formData.readGroups || [formData['vcs-read-group'] || formData['tep-read-group'] || formData['read-group']].filter(Boolean);

                const finalP = p.filter(val => !a.includes(val));
                const finalR = r.filter(val => !a.includes(val) && !finalP.includes(val));

                if (p.length !== finalP.length || r.length !== finalR.length) {
                    infoMessages.push("Redundant groups collapsed.");
                }

                if (validationErrors.length > 0) {
                    showStatus(validationErrors.join(" | "), "error");
                    return null;
                }
                return formData;
}

// ==========================================
// 6. REVIEW & SUBMISSION FLOW
// ==========================================
workspaceForm.addEventListener('submit', function(event) {
    event.preventDefault();
    const data = gatherFormData();
    if (data) {
        finalValidatedData = data;
        renderReview(data);
        reviewModal.style.display = "flex";
    }
});

confirmSubmitBtn.addEventListener('click', async function() {
    closeModal();
    const submitBtn = document.getElementById('submitBtn');
    submitBtn.innerText = "🚀 Processing...";
    submitBtn.disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(finalValidatedData)
        });
        const result = await response.json();

        if (response.ok) {
            showStatus(`Success! Request ID: ${result.requestId || 'Queued'}.`, "success");
            workspaceForm.reset();
            clearDynamicLists();
        } else {
            throw new Error(result.message || "Request rejected.");
        }
    } catch (err) {
        showStatus("Submission Failed: " + err.message, "error");
    } finally {
        submitBtn.innerText = "Submit Request";
        submitBtn.disabled = false;
    }
});

// ==========================================
// 7. UI HELPERS (Status & Review)
// ==========================================
function renderReview(data) {
    reviewContainer.innerHTML = "";

    let html = `
    <div style="background: #fff; padding: 15px; border-radius: 5px; border: 1px solid #ddd;">
    <table style="width:100%; border-collapse: collapse; font-family: sans-serif; font-size: 14px;">
    `;

    for (const [key, value] of Object.entries(data)) {
        const displayValue = Array.isArray(value) ? value.join(", ") : value;
        if (displayValue && displayValue !== "") {
            const cleanKey = key.replace(/-/g, ' ').toUpperCase();
            html += `
            <tr style="border-bottom: 1px solid #eee;">
            <td style="padding: 10px; color: #555; font-weight: bold; width: 40%;">${cleanKey}</td>
            <td style="padding: 10px; color: #000;">${displayValue}</td>
            </tr>`;
        }
    }
    html += "</table></div>";
    reviewContainer.innerHTML = html;
}

function showStatus(msg, type) {
    errorBanner.style.display = 'block';
    if (type === "success") {
        errorBanner.style.backgroundColor = "#d4edda";
        errorBanner.style.color = "#155724";
        errorBanner.style.borderColor = "#c3e6cb";
        errorBanner.innerText = "✅ " + msg;
    } else {
        errorBanner.style.backgroundColor = "#f8d7da";
        errorBanner.style.color = "#721c24";
        errorBanner.style.borderColor = "#f5c6cb";
        errorBanner.innerText = "⚠️ " + msg;
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function showError(msg) { showStatus(msg, "error"); }
