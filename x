 grep -n "export function\|export const\|return " src/components/modal.js 
28:export function openModal({ title, content, onClose, dismissable = true }) {
81:  return modal;
87:export function closeModal(modal) {
119:  if (str == null) return '';
120:  return String(str)
