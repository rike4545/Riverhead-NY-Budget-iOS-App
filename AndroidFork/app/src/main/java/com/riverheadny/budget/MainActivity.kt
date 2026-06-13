package com.riverheadny.budget

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContactMail
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Newspaper
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.roundToInt

private val BrandNavy = Color(0xFF19537B)
private val BrandBlue = Color(0xFF4E7595)
private val BrandSky = Color(0xFF4285A7)
private val BrandTeal = Color(0xFF8DBABE)
private val BrandGold = Color(0xFFBDAC34)
private val BrandMint = Color(0xFF4A9885)
private val BrandCoral = Color(0xFFC6503C)
private val Page = Color(0xFFEBF1F4)
private val CardSurface = Color(0xFFFBFCFE)

enum class RootTab(val label: String, val icon: ImageVector) {
    Home("Home", Icons.Filled.Home),
    Budget("Budget", Icons.Filled.Assessment),
    Discover("Discover", Icons.Filled.Search),
    Toolkits("Toolkits", Icons.Filled.People),
    More("More", Icons.Filled.MoreHoriz)
}

enum class AudienceMode(val label: String, val subtitle: String) {
    Resident("Resident", "Plain language and examples"),
    Expert("Expert", "Detailed views and numbers")
}

data class BudgetDoc(
    val title: String,
    val type: String,
    val year: Int,
    val url: String,
    val published: String
)

data class ToolLink(
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val url: String? = null
)

private val budgetDocs = listOf(
    BudgetDoc("2026 Tentative Budget", "Tentative", 2026, "https://www.townofriverheadny.gov/DocumentCenter/View/2779/2026-Tentative-Budget-PDF", "Oct. 1, 2025"),
    BudgetDoc("2026 Budget Supplement", "Financial reference", 2026, "https://www.townofriverheadny.gov/DocumentCenter/View/2780/2026-Budget-Supplement-PDF", "Oct. 1, 2025"),
    BudgetDoc("2025 Adopted Budget", "Adopted", 2025, "https://www.townofriverheadny.gov/DocumentCenter/View/243/2025-Adopted-Budget-PDF", "Nov. 20, 2024"),
    BudgetDoc("2025 Tentative Budget", "Tentative", 2025, "https://www.townofriverheadny.gov/DocumentCenter/View/242/2025-Tentative-Budget-PDF", "Oct. 1, 2024"),
    BudgetDoc("2024 Adopted Budget", "Adopted", 2024, "https://www.townofriverheadny.gov/DocumentCenter/View/245/2024-Adopted-Budget-PDF", "Nov. 20, 2023")
)

private val quickLinks = listOf(
    ToolLink("Town Website", "Official Town of Riverhead home page", Icons.Filled.Link, "https://www.townofriverheadny.gov/"),
    ToolLink("Channel 22", "Live streams and meeting archives", Icons.Filled.Newspaper, "https://www.townofriverheadny.gov/462/Channel-22---Live-Streams-and-Video-Arch"),
    ToolLink("Code Complaint", "Official code enforcement complaint form", Icons.Filled.ContactMail, "https://www.townofriverheadny.gov/FormCenter/Code-Enforcement-10/Online-Code-Enforcement-Violation-Compla-53"),
    ToolLink("Online Payments", "Taxes, payments, and online services", Icons.Filled.Calculate, "https://www.townofriverheadny.gov/164/Online-Payments-Services")
)

private val budgetSections = listOf(
    ToolLink("Overview", "Plain-English 2026 budget context and key drivers", Icons.Filled.Assessment),
    ToolLink("2027 Lab", "Scenario workspace for next budget year", Icons.Filled.Settings),
    ToolLink("My Taxes", "Estimate impact from assessed value and tax rate", Icons.Filled.Calculate),
    ToolLink("Fund Balance", "Policy target, reserve gap, and surplus checks", Icons.Filled.AccountBalance),
    ToolLink("Capital & Debt", "Capital plan, borrowing, and off-balance items", Icons.AutoMirrored.Filled.TrendingUp),
    ToolLink("Employees", "Gross earnings and labor contract explorer", Icons.Filled.People),
    ToolLink("Hearing Toolkit", "Questions and talking points for residents", Icons.Filled.VolunteerActivism),
    ToolLink("Glossary", "Budget terms translated into practical language", Icons.Filled.Description)
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RiverheadBudgetApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RiverheadBudgetApp() {
    var selectedTab by remember { mutableStateOf(RootTab.Home) }

    MaterialTheme(
        colorScheme = androidx.compose.material3.lightColorScheme(
            primary = BrandBlue,
            secondary = BrandTeal,
            tertiary = BrandGold,
            background = Page,
            surface = CardSurface
        )
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Riverhead NY Budget", maxLines = 1, overflow = TextOverflow.Ellipsis) },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = CardSurface)
                )
            },
            bottomBar = {
                NavigationBar(containerColor = CardSurface) {
                    RootTab.entries.forEach { tab ->
                        NavigationBarItem(
                            selected = selectedTab == tab,
                            onClick = { selectedTab = tab },
                            icon = { Icon(tab.icon, contentDescription = tab.label) },
                            label = { Text(tab.label) }
                        )
                    }
                }
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Page)
                    .padding(padding)
            ) {
                when (selectedTab) {
                    RootTab.Home -> HomeScreen()
                    RootTab.Budget -> BudgetHubScreen()
                    RootTab.Discover -> DiscoverScreen()
                    RootTab.Toolkits -> ToolkitsScreen()
                    RootTab.More -> MoreScreen()
                }
            }
        }
    }
}

@Composable
private fun HomeScreen() {
    PageColumn {
        HeroCard(
            eyebrow = "Riverhead NY",
            title = "Unofficial civic & budget companion",
            body = "Services, taxes, budget documents, and clear resident tools in one Android fork."
        )

        StatusCard()
        SectionTitle("Town Services")
        quickLinks.forEach { LinkCard(it) }
        SectionTitle("Budget Tools")
        budgetSections.take(4).forEach { ToolCard(it) }
        DisclaimerCard()
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun BudgetHubScreen() {
    var mode by remember { mutableStateOf(AudienceMode.Resident) }
    var selected by remember { mutableStateOf("Overview") }

    PageColumn {
        HeroCard(
            eyebrow = "Budget Hub",
            title = "Resident & Expert Tools",
            body = "Switch audience mode, then jump into taxes, fund balance, capital plans, employees, and hearings."
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            AudienceMode.entries.forEach { item ->
                FilterChip(
                    selected = mode == item,
                    onClick = { mode = item },
                    label = { Text(item.label) }
                )
            }
        }
        Text(mode.subtitle, color = Color.DarkGray, style = MaterialTheme.typography.bodySmall)

        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            budgetSections.forEach { item ->
                FilterChip(
                    selected = selected == item.title,
                    onClick = { selected = item.title },
                    label = { Text(item.title) },
                    leadingIcon = { Icon(item.icon, contentDescription = null, modifier = Modifier.size(18.dp)) }
                )
            }
        }

        when (selected) {
            "My Taxes" -> TaxEstimatorCard()
            "Fund Balance" -> FundBalanceCard()
            "Employees" -> EmployeeExplorerCard()
            "Hearing Toolkit" -> HearingToolkitCard()
            else -> BudgetDetailCard(selected, mode)
        }

        SectionTitle("Budget Documents")
        budgetDocs.forEach { BudgetDocCard(it) }
    }
}

@Composable
private fun DiscoverScreen() {
    PageColumn {
        HeroCard("Discover", "Civic Command Center", "Improvement ideas, scorecards, local signals, and public-meeting context.")
        listOf(
            ToolLink("Civic Improvements", "Project ideas, resident impact, and action paths", Icons.Filled.VolunteerActivism),
            ToolLink("Council Scorecard", "Track civic questions, votes, and follow-through", Icons.Filled.CheckCircle),
            ToolLink("Budget Signals", "Risk flags and context for the current budget", Icons.AutoMirrored.Filled.TrendingUp),
            ToolLink("Town Code", "eCode360 lookup entry point", Icons.Filled.Search, "https://ecode360.com/RI0756")
        ).forEach { if (it.url == null) ToolCard(it) else LinkCard(it) }
    }
}

@Composable
private fun ToolkitsScreen() {
    PageColumn {
        HeroCard("Toolkits", "Resident Action Toolkit", "Templates and checklists for hearings, budget questions, records, and local services.")
        listOf(
            ToolLink("Start Here", "Pick the quickest path for a budget or service question", Icons.Filled.Info),
            ToolLink("Source Trail", "Know what document backs each claim", Icons.Filled.CheckCircle),
            ToolLink("Saved Scenarios", "Keep personal budget and tax what-ifs", Icons.Filled.Description),
            ToolLink("Export & Share", "Prepare a concise summary for email or meetings", Icons.Filled.ContactMail),
            ToolLink("Ask AI", "Android placeholder for the iOS AI helper flow", Icons.Filled.SmartToy)
        ).forEach { ToolCard(it) }
    }
}

@Composable
private fun MoreScreen() {
    PageColumn {
        HeroCard("More", "Riverhead shortcuts", "Official links, budget history, app info, and transparency notes.")
        listOf(
            ToolLink("Departments", "Official Town departments directory", Icons.Filled.People, "https://www.townofriverheadny.gov/31/Departments"),
            ToolLink("Government", "Boards, committees, and elected offices", Icons.Filled.AccountBalance, "https://www.townofriverheadny.gov/27/Government"),
            ToolLink("News & Events", "Official announcements and calendar", Icons.Filled.Newspaper, "https://www.townofriverheadny.gov/CivicAlerts.asp?CID=1"),
            ToolLink("Receiver of Taxes", "Official tax receiver page", Icons.Filled.Calculate, "https://www.townofriverheadny.gov/189/Receiver-of-Taxes"),
            ToolLink("Financial Reports", "Official annual financial reports", Icons.Filled.Description, "https://www.townofriverheadny.gov/206/Financial-Reports"),
            ToolLink("Feedback", "App feedback form", Icons.Filled.ContactMail, "https://qualtricsxmm8q5gxrhq.qualtrics.com/jfe/form/SV_1TvkCrIKgaEYHPM")
        ).forEach { LinkCard(it) }
        DisclaimerCard()
    }
}

@Composable
private fun PageColumn(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        content = content
    )
}

@Composable
private fun HeroCard(eyebrow: String, title: String, body: String) {
    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = BrandNavy),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .background(Brush.linearGradient(listOf(BrandNavy, BrandSky, BrandTeal, BrandGold)))
                .padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(eyebrow, color = Color.White.copy(alpha = 0.84f), style = MaterialTheme.typography.labelLarge)
            Text(title, color = Color.White, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text(body, color = Color.White.copy(alpha = 0.92f), style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
private fun StatusCard() {
    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = BrandMint)
            Spacer(Modifier.width(12.dp))
            Column {
                Text("${budgetDocs.size} budget documents available", fontWeight = FontWeight.SemiBold)
                Text("Coverage: ${budgetDocs.minOf { it.year }}-${budgetDocs.maxOf { it.year }}", color = Color.DarkGray)
            }
        }
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = BrandNavy)
}

@Composable
private fun ToolCard(link: ToolLink) {
    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(link.icon, contentDescription = null, tint = BrandBlue)
            Spacer(Modifier.width(12.dp))
            Column {
                Text(link.title, fontWeight = FontWeight.SemiBold)
                Text(link.subtitle, color = Color.DarkGray, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun LinkCard(link: ToolLink) {
    val context = LocalContext.current
    ElevatedCard(
        onClick = {
            link.url?.let { context.startActivity(Intent(Intent.ACTION_VIEW, it.toUri())) }
        },
        colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)
    ) {
        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(link.icon, contentDescription = null, tint = BrandBlue)
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(link.title, fontWeight = FontWeight.SemiBold)
                Text(link.subtitle, color = Color.DarkGray, style = MaterialTheme.typography.bodySmall)
            }
            Icon(Icons.Filled.Link, contentDescription = null, tint = BrandGold)
        }
    }
}

@Composable
private fun BudgetDetailCard(section: String, mode: AudienceMode) {
    val expertCopy = when (section) {
        "Capital & Debt" -> "Model debt service, BAN exposure, capital project status, and off-balance obligations."
        "2027 Lab" -> "Use year-over-year assumptions to shape next-cycle levy, staffing, and reserve scenarios."
        "Glossary" -> "Crosswalk budget terms with resident-facing explanations and source document references."
        else -> "Detailed mode preserves line-item context, audit flags, source trails, and forecast assumptions."
    }
    val residentCopy = when (section) {
        "Overview" -> "See what changed, what matters to household taxes, and what to verify in the adopted budget."
        "2027 Lab" -> "Try simple what-if choices and see how they could affect services or taxes."
        "Glossary" -> "Translate budget language into everyday terms."
        else -> "Start with a short explanation, then drill into the numbers when needed."
    }
    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(section, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(if (mode == AudienceMode.Expert) expertCopy else residentCopy, color = Color.DarkGray)
            MetricRow("2026 appropriations", currency(69_113_159.0))
            MetricRow("Estimated unassigned fund balance", currency(28_403_924.0))
            MetricRow("Illustrative tax rate", "$22.50 per $1,000")
        }
    }
}

@Composable
private fun TaxEstimatorCard() {
    var assessedValue by remember { mutableFloatStateOf(450_000f) }
    var rate by remember { mutableFloatStateOf(22.5f) }
    val tax = assessedValue / 1000f * rate

    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("My Taxes", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            MetricRow("Assessed value", currency(assessedValue.toDouble()))
            Slider(value = assessedValue, onValueChange = { assessedValue = it }, valueRange = 100_000f..1_500_000f, steps = 27)
            MetricRow("Rate per $1,000", "$${"%.2f".format(rate)}")
            Slider(value = rate, onValueChange = { rate = it }, valueRange = 10f..40f)
            MetricRow("Estimated tax", currency(tax.toDouble()))
        }
    }
}

@Composable
private fun FundBalanceCard() {
    val appropriations = 69_113_159.0
    val fundBalance = 28_403_924.0
    val minimum = appropriations * 0.15
    val target = appropriations * 0.20

    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Fund Balance", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("Policy check using the iOS app's current general-fund assumptions.", color = Color.DarkGray)
            MetricRow("Minimum reserve", currency(minimum))
            MetricRow("Upper target", currency(target))
            MetricRow("Estimated balance", currency(fundBalance))
            MetricRow("Above upper target", currency(fundBalance - target))
        }
    }
}

@Composable
private fun EmployeeExplorerCard() {
    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Employees", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("The Android fork includes CSV asset slots for gross earnings, payroll, and labor contract inputs.", color = Color.DarkGray)
            MetricRow("Earnings coverage", "2018-2023")
            MetricRow("Labor groups", "PBA, SOA, CSEA, Exempt")
            MetricRow("Next step", "Wire CSV parsing into searchable tables")
        }
    }
}

@Composable
private fun HearingToolkitCard() {
    ElevatedCard(colors = CardDefaults.elevatedCardColors(containerColor = CardSurface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Hearing Toolkit", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            listOf(
                "What changed from the adopted 2025 budget?",
                "Which fund-balance policy is being applied?",
                "Which assumptions drive 2027 staffing and labor cost projections?",
                "Which claims are backed by adopted documents versus estimates?"
            ).forEach { Text("• $it", color = Color.DarkGray) }
        }
    }
}

@Composable
private fun BudgetDocCard(doc: BudgetDoc) {
    val context = LocalContext.current
    Card(
        onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, doc.url.toUri())) },
        colors = CardDefaults.cardColors(containerColor = CardSurface),
        shape = RoundedCornerShape(14.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(doc.title, fontWeight = FontWeight.SemiBold)
            Text("${doc.type} • ${doc.year} • ${doc.published}", color = Color.DarkGray, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun DisclaimerCard() {
    Card(colors = CardDefaults.cardColors(containerColor = BrandCoral.copy(alpha = 0.10f))) {
        Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.Top) {
            Icon(Icons.Filled.Info, contentDescription = null, tint = BrandCoral)
            Spacer(Modifier.width(10.dp))
            Text("Not an official Town app. Always verify with the Town website, adopted budget, and official records.", color = Color(0xFF5F2B23))
        }
    }
}

@Composable
private fun MetricRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Color.DarkGray)
        Text(value, fontWeight = FontWeight.SemiBold, color = BrandNavy)
    }
}

private fun currency(value: Double): String =
    NumberFormat.getCurrencyInstance(Locale.US).format(value.roundToInt())

@Preview(showBackground = true)
@Composable
private fun AppPreview() {
    RiverheadBudgetApp()
}
