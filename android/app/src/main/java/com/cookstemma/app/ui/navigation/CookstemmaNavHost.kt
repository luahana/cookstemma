package com.cookstemma.app.ui.navigation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.cookstemma.app.data.auth.GoogleSignInManager
import com.cookstemma.app.data.auth.GoogleSignInResult
import com.cookstemma.app.ui.AppState
import com.cookstemma.app.ui.rememberAppState
import com.cookstemma.app.ui.screens.SplashScreen
import com.cookstemma.app.ui.screens.auth.AuthViewModel
import com.cookstemma.app.ui.screens.auth.LoginBottomSheet
import com.cookstemma.app.ui.screens.create.CreateLogScreen
import com.cookstemma.app.ui.screens.home.HomeFeedScreen
import com.cookstemma.app.ui.screens.profile.ProfileScreen
import com.cookstemma.app.ui.screens.recipe.RecipeDetailScreen
import com.cookstemma.app.ui.screens.recipes.RecipesListScreen
import com.cookstemma.app.ui.screens.log.EditLogScreen
import com.cookstemma.app.ui.screens.logdetail.LogDetailScreen
import com.cookstemma.app.ui.screens.profile.FollowersScreen
import com.cookstemma.app.ui.screens.hashtag.HashtagDetailScreen
import com.cookstemma.app.ui.screens.settings.BlockedUsersScreen
import com.cookstemma.app.ui.screens.settings.EditProfileScreen
import com.cookstemma.app.ui.screens.settings.MeasurementUnitsScreen
import com.cookstemma.app.ui.screens.settings.NotificationSettingsScreen
import com.cookstemma.app.ui.screens.settings.SettingsScreen
import kotlinx.coroutines.launch

@Composable
fun CookstemmaNavHost(
    authViewModel: AuthViewModel = hiltViewModel(),
    googleSignInManager: GoogleSignInManager
) {
    val authUiState by authViewModel.uiState.collectAsState()
    val appState = rememberAppState()
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    
    // Determine auth state from repository
    // isInitialCheckComplete tells us if we've finished the initial auth check
    val showSplash = !authUiState.isInitialCheckComplete

    // Dismiss login sheet when authentication succeeds
    LaunchedEffect(authUiState.isAuthenticated) {
        if (authUiState.isAuthenticated && appState.showLoginSheet) {
            appState.onLoginSuccess()
        }
    }

    if (showSplash) {
        // Show splash while determining auth state
        SplashScreen()
    } else {
        // Show main content for both authenticated and unauthenticated users
        MainContent(
            appState = appState,
            isAuthenticated = authUiState.isAuthenticated
        )
        
        // Login bottom sheet overlay
        if (appState.showLoginSheet) {
            LoginBottomSheet(
                onDismiss = { appState.onLoginDismissed() },
                onLoginSuccess = { appState.onLoginSuccess() },
                onGoogleSignIn = { 
                    coroutineScope.launch {
                        when (val result = googleSignInManager.signIn(context)) {
                            is GoogleSignInResult.Success -> {
                                authViewModel.loginWithFirebase(result.firebaseIdToken)
                            }
                            is GoogleSignInResult.Error -> {
                                // Error is shown via AuthViewModel's uiState
                                authViewModel.setError(result.message)
                            }
                            is GoogleSignInResult.Cancelled -> {
                                // User cancelled, do nothing
                            }
                        }
                    }
                },
                onAppleSignIn = {
                    // Apple Sign-In is not available on Android
                    // This button could be hidden or show a message
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainContent(
    appState: AppState,
    isAuthenticated: Boolean
) {
    val navController = rememberNavController()
    var showCreateSheet by remember { mutableStateOf(false) }

    // Scroll-to-top triggers for each tab (increment to trigger scroll)
    var homeScrollTrigger by remember { mutableStateOf(0) }
    var recipesScrollTrigger by remember { mutableStateOf(0) }
    var searchScrollTrigger by remember { mutableStateOf(0) }
    var profileScrollTrigger by remember { mutableStateOf(0) }

    // Handle tab reselect for scroll-to-top
    val onTabReselect: (String) -> Unit = { route ->
        when (route) {
            BottomNavItem.Home.route -> homeScrollTrigger++
            BottomNavItem.Recipes.route -> recipesScrollTrigger++
            BottomNavItem.Search.route -> searchScrollTrigger++
            BottomNavItem.Profile.route -> profileScrollTrigger++
        }
    }

    Scaffold(
        bottomBar = {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentRoute = navBackStackEntry?.destination?.route
            val showBottomBar = currentRoute in listOf(
                BottomNavItem.Home.route,
                BottomNavItem.Recipes.route,
                BottomNavItem.Search.route,
                BottomNavItem.Profile.route
            )
            if (showBottomBar) {
                CustomBottomBar(
                    navController = navController,
                    onCreateClick = {
                        appState.requireAuth(isAuthenticated) {
                            showCreateSheet = true
                        }
                    },
                    notificationCount = 0,
                    appState = appState,
                    isAuthenticated = isAuthenticated,
                    onTabReselect = onTabReselect
                )
            }
        }
    ) { innerPadding ->
        // Only apply bottom padding for navigation bar; each screen handles its own top padding
        NavHost(
            navController = navController,
            startDestination = BottomNavItem.Home.route,
            modifier = Modifier.padding(PaddingValues(bottom = innerPadding.calculateBottomPadding()))
        ) {
            composable(BottomNavItem.Home.route) {
                HomeFeedScreen(
                    onRecipeClick = { navController.navigate("recipe/$it") },
                    onLogClick = { navController.navigate("log/$it") },
                    onUserClick = { navController.navigate("user/$it") },
                    onHashtagClick = { tag -> navController.navigate("hashtag/$tag") },
                    scrollToTopTrigger = homeScrollTrigger,
                    appState = appState,
                    isAuthenticated = isAuthenticated
                )
            }
            composable(BottomNavItem.Recipes.route) {
                RecipesListScreen(
                    onRecipeClick = { navController.navigate("recipe/$it") },
                    scrollToTopTrigger = recipesScrollTrigger,
                    appState = appState,
                    isAuthenticated = isAuthenticated
                )
            }
            composable(BottomNavItem.Search.route) {
                com.cookstemma.app.ui.screens.search.SearchScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToRecipe = { navController.navigate("recipe/$it") },
                    onNavigateToLog = { navController.navigate("log/$it") },
                    onNavigateToProfile = { navController.navigate("user/$it") },
                    onNavigateToHashtag = { tag -> navController.navigate("hashtag/$tag") }
                )
            }
            composable(BottomNavItem.Profile.route) {
                ProfileScreen(
                    userId = null,
                    appState = appState,
                    isAuthenticated = isAuthenticated,
                    onRecipeClick = { navController.navigate("recipe/$it") },
                    onLogClick = { navController.navigate("log/$it") },
                    onSettingsClick = { navController.navigate("settings") },
                    onFollowersClick = { userId -> navController.navigate("followers/$userId") }
                )
            }
            composable("recipe/{recipeId}", listOf(navArgument("recipeId") { type = NavType.StringType })) { entry ->
                val recipeId = entry.arguments?.getString("recipeId") ?: return@composable
                RecipeDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToLog = { logId -> navController.navigate("log/$logId") },
                    onNavigateToProfile = { userId -> navController.navigate("user/$userId") },
                    onCreateLog = { navController.navigate("create-log?recipeId=$recipeId") },
                    appState = appState,
                    isAuthenticated = isAuthenticated
                )
            }
            composable("log/{logId}", listOf(navArgument("logId") { type = NavType.StringType })) { entry ->
                val logId = entry.arguments?.getString("logId") ?: return@composable
                LogDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToRecipe = { recipeId -> navController.navigate("recipe/$recipeId") },
                    onNavigateToProfile = { userId -> navController.navigate("user/$userId") },
                    onNavigateToEdit = { navController.navigate("log/$logId/edit") },
                    appState = appState,
                    isAuthenticated = isAuthenticated
                )
            }
            composable(
                "log/{logId}/edit",
                listOf(navArgument("logId") { type = NavType.StringType })
            ) {
                EditLogScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onSaveSuccess = { navController.popBackStack() },
                    onDeleteSuccess = {
                        navController.popBackStack("log/{logId}", inclusive = true)
                        navController.popBackStack()
                    }
                )
            }
            composable("user/{userId}", listOf(navArgument("userId") { type = NavType.StringType })) { entry ->
                ProfileScreen(
                    userId = entry.arguments?.getString("userId"),
                    onRecipeClick = { navController.navigate("recipe/$it") },
                    onLogClick = { navController.navigate("log/$it") },
                    onSettingsClick = { },
                    onFollowersClick = { userId -> navController.navigate("followers/$userId") }
                )
            }

            // Settings routes
            composable("settings") {
                SettingsScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToEditProfile = { navController.navigate("settings/edit-profile") },
                    onNavigateToNotificationSettings = { navController.navigate("settings/notifications") },
                    onNavigateToBlockedUsers = { navController.navigate("settings/blocked-users") },
                    onNavigateToMeasurementUnits = { navController.navigate("settings/measurement-units") },
                    onLogoutSuccess = {
                        navController.navigate(BottomNavItem.Home.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
            composable("settings/edit-profile") {
                EditProfileScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onSaveSuccess = { navController.popBackStack() }
                )
            }
            composable("settings/blocked-users") {
                BlockedUsersScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }
            composable("settings/notifications") {
                NotificationSettingsScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }
            composable("settings/measurement-units") {
                MeasurementUnitsScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            // Followers route
            composable(
                "followers/{userId}",
                listOf(navArgument("userId") { type = NavType.StringType })
            ) {
                FollowersScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToProfile = { userId -> navController.navigate("user/$userId") }
                )
            }

            // Hashtag route
            composable(
                "hashtag/{tag}",
                listOf(navArgument("tag") { type = NavType.StringType })
            ) {
                HashtagDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToLog = { logId -> navController.navigate("log/$logId") },
                    onNavigateToRecipe = { recipeId -> navController.navigate("recipe/$recipeId") }
                )
            }

            // Create Log route (with optional recipe pre-population)
            composable(
                route = "create-log?recipeId={recipeId}",
                arguments = listOf(
                    navArgument("recipeId") {
                        type = NavType.StringType
                        nullable = true
                        defaultValue = null
                    }
                )
            ) {
                ModalBottomSheet(
                    onDismissRequest = { navController.popBackStack() },
                    sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
                    modifier = Modifier.navigationBarsPadding()
                ) {
                    CreateLogScreen(
                        onDismiss = { navController.popBackStack() },
                        onSuccess = { navController.popBackStack() }
                    )
                }
            }
        }
    }
    
    // Create Log Bottom Sheet
    if (showCreateSheet) {
        ModalBottomSheet(
            onDismissRequest = { showCreateSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            modifier = Modifier.navigationBarsPadding()
        ) {
            CreateLogScreen(
                onDismiss = { showCreateSheet = false },
                onSuccess = { showCreateSheet = false }
            )
        }
    }
}