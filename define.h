#ifndef DEFINE_H
#define DEIFNE_H

typedef struct Value Value;
struct Value {
	int i_val;
	float f_val;
	int b_val;
	char *string;
	char *id_name;
};
typedef struct Ent Ent;
struct Ent {
	int index;
	char *name;
	char *kind;
	char *type;
	int scope;
	char *attribute;
	Ent *next;

};
typedef struct Table Table;
struct Table {
	int table_count;
	Ent *head;
	Ent *tail;
	Table *prev;
	int entry_count;
};
#endif


