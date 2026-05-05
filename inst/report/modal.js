let modalTrigger = null;

function getFocusableElements(container) {
  return Array.from(
    container.querySelectorAll(
      'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])',
    ),
  ).filter(function (el) {
    return (
      el.offsetWidth > 0 ||
      el.offsetHeight > 0 ||
      el.getClientRects().length > 0
    );
  });
}

function closeModal() {
  const modal = document.getElementById("details-modal");
  if (!modal.classList.contains("active")) return;

  modal.classList.remove("active");
  modal.setAttribute("aria-hidden", "true");

  if (modalTrigger) {
    modalTrigger.focus();
    modalTrigger = null;
  }
}

function openModal(btn) {
  const modal = document.getElementById("details-modal");
  const modalDialog = modal.querySelector(".modal-content");

  document.getElementById("modal-rule-id").textContent =
    btn.dataset.ruleId || "";
  document.getElementById("modal-explanation").textContent =
    btn.dataset.explanation || "";
  document.getElementById("modal-iso").textContent = btn.dataset.iso || "";
  document.getElementById("modal-clause").textContent =
    btn.dataset.clause || "";
  document.getElementById("modal-verapdf").textContent =
    btn.dataset.verapdf || "";

  modalTrigger = btn;
  modal.classList.add("active");
  modal.setAttribute("aria-hidden", "false");
  modalDialog.focus();
}

function trapModalFocus(e) {
  const modal = document.getElementById("details-modal");
  if (!modal.classList.contains("active")) return;

  const modalDialog = modal.querySelector(".modal-content");
  const focusableElements = getFocusableElements(modalDialog);

  if (focusableElements.length === 0) {
    e.preventDefault();
    modalDialog.focus();
    return;
  }

  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  if (e.shiftKey && document.activeElement === firstElement) {
    e.preventDefault();
    lastElement.focus();
  } else if (e.shiftKey && document.activeElement === modalDialog) {
    e.preventDefault();
    lastElement.focus();
  } else if (!e.shiftKey && document.activeElement === lastElement) {
    e.preventDefault();
    firstElement.focus();
  }
}

document.addEventListener("click", function (e) {
  const btn = e.target.closest(".more-info-btn");
  if (btn) {
    openModal(btn);
  }
});

document.addEventListener("keydown", function (e) {
  if (e.key === "Escape") closeModal();
  if (e.key === "Tab") trapModalFocus(e);
});
