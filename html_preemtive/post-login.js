const navLinks = document.querySelectorAll(".menu a");
const currentPage = window.location.pathname.split("/").pop();

navLinks.forEach((link) => {
    const linkPage = link.getAttribute("href");
    if (linkPage === currentPage) {
        link.classList.add("active");
    }
});
