// Επεξεργάζεται την παραγγελία ενός πελάτη
void process_order(int product_id, int customer_pid);

// Δημιουργεί τους αγωγούς και fork-άρει τις διεργασίες πελατών
void create_pipes_and_fork_customers();

// Αρχικοποιεί τον κατάλογο προϊόντων και τις στατιστικές
void initialize_catalog();

// Παράγει την τελική αναφορά παραγγελιών
void generate_report();

// Εμφανίζει το σύνολο των αγορών κάθε πελάτη
void print_customer_totals();
