module parser

# Classe d'utilitaires
class Parser
        var input_string: String

        var first: Int
        var last: Int

        init (s: String, first: nullable Int, last: nullable Int) do
                s = s.replace(" ", "")
                self.input_string = s
                
                if first == null or last == null then
                        self.first = 0
                        self.last = s.length - 1
                else if first >= 0 and last >= first then
                        self.first = first
                        self.last = last
                else
                        throw_error(s, first, "Expected expression, found nothing")
                end
        end
        
        # Supprime les parenthèses englobant une expression
        private fun remove_englobing: Bool do
                # Recherche du pattern (p)
                if self.input_string[self.first] == '(' and self.input_string[self.last] == ')' then
                        var open = 0

                        # Vérification des parenthèses dans le pattern p
                        for i in [self.first + 1..self.last - 1] do
                                if input_string[i] == '(' then
                                        open = open + 1
                                else if open > 0 and input_string[i] == ')' then
                                        open = open - 1
                                end
                        end

                        # Rabot des index de début et fin
                        if open == 0 then
                                self.first = self.first + 1
                                self.last = self.last - 1
                                remove_englobing
                                return true
                        end
                end
                return false
        end

        # Parse une expression
        fun parse(top_operator: nullable Operator): Expression do
                var has_englobing = self.remove_englobing

                if self.last - self.first == 0 then
                        # Un caractère, probablement une variable
                        return new UnaryExpression(input_string, first, last)
                else
                        # Plus d'un caractère, potentiellement une expression binaire
                        return new BinaryExpression(input_string, first, last, top_operator, has_englobing)
                end
        end
end

# Abstraction d'expression
interface Expression
        fun format: String is abstract
end

# Expression de la forme operande operateur operande
class BinaryExpression
        super Expression
        
        var left_operand: nullable Expression = null
        var right_operand: nullable Expression = null
        var operator: nullable Operator = null

        # L'opérateur de l'expression du niveau supérieur, s'il y a lieu
        var top_operator: nullable Operator = null
        # Indique la présence de parenthèses dans la chaîne d'entrée
        var has_englobing: Bool = false

        init (s: String, first: Int, last: Int, top_operator: nullable Operator, has_englobing: Bool) do
                var open = 0
                var position = first
                var c = ' '

                # Recherche de l'opérateur de plus haut niveau
                # (le premier caractère hors parenthèses)
                for i in [first..last] do
                        c = s[i]

                        position = i

                        if c == '(' then
                                open = open + 1
                        else if open > 0 and c == ')' then
                                open = open - 1
                        else if open == 0 then
                                if i != first then
                                        # Pas de parenthèses ouvertes, deuxième caractère: doit être l'opérateur
                                        self.operator = new Operator.from_string(s, i)
                                        break
                                else if not c.is_letter then
                                        # Premier caractère sans parenthèses ouvertes : doit être une variable
                                        throw_error(s, i, "Expected variable, found \"{c}\"")
                                end
                        end
                end

                # Opérateur non trouvé
                if self.operator == null then
                        throw_error(s, position, "Expected operator or end of string, found \"{c}\"")
                end
                
                # Création récursive des sous-expressions
                self.left_operand = (new Parser(s, first, position - 1)).parse(self.operator)
                self.right_operand = (new Parser(s, position + 1, last)).parse(self.operator)
                self.top_operator = top_operator
                self.has_englobing = has_englobing
        end

        redef fun format do
                var text = left_operand.format + operator.to_s + right_operand.format
                # On conserve les parenthèses de la chaîne d'entrée à deux conditions :
                # L'opérateur de plus haut niveau est prioritaire, ou
                # l'opérateur de plus haut niveau n'est pas commutatif
                if self.top_operator != null and
                   self.has_englobing and
                   (self.top_operator.priority < self.operator.priority or not self.top_operator.commutative) then
                        return "(" + text + ")"
                else
                        return text
                end
        end
end

# Expression à opérande unique
class UnaryExpression
        super Expression

        var operand: Char
        
        init (s: String, first: Int, last: Int) do
                if s[first].is_letter then
                        self.operand = s[first]
                else
                        throw_error(s, first, "Expected variable, found \"{s[first]}\"")
                end
        end

        redef fun format do
                return operand.to_s
        end
end

class Operator
        var symbol: Char
        var priority: Int
        var commutative: Bool

        init from_string(s: String, position: Int) do
                var c = s[position]

                self.symbol = c
                self.commutative = false
                if c == '^' then
                        self.priority = 1
                else if c == '*' then
                        self.priority = 2
                        self.commutative = true
                else if c == '/' then
                        self.priority = 2
                else if c == '+' then
                        self.priority = 3
                        self.commutative = true
                else if c == '-' then
                        self.priority = 3
                else
                        throw_error(s, position, "Expected operator, found \"{c}\"")
                end
        end

        redef fun to_s do
                return " " + self.symbol.to_s + " "
        end
end

fun throw_error(string: String, index: Int, description: String) do
        print string
        for i in [0..index - 1] do
                printn " "
        end
        print "^"
        print description
        exit(0)
end

var input_string = args.join("")
var expression: Expression = (new Parser(input_string, null, null)).parse(null)

print expression.format

